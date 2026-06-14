//
//  EPUBParser.swift
//  ChatPrinter
//
//  EPUB 解析器 - 使用原生 ZIP/XML 解析
//

import Foundation
import AppKit

class EPUBParser {

    enum EPUBError: Error, LocalizedError {
        case invalidFormat
        case cannotUnzip
        case noContent

        var errorDescription: String? {
            switch self {
            case .invalidFormat: return "EPUB 格式无效"
            case .cannotUnzip: return "无法解压 EPUB 文件"
            case .noContent: return "EPUB 中没有内容"
            }
        }
    }

    struct EPUBBook {
        var title: String
        var creator: String
        var chapters: [EPUBChapter]
    }

    struct EPUBChapter: Identifiable {
        let id = UUID()
        var title: String
        var content: String  // 原始 HTML
        var fileName: String
    }

    // MARK: - 解析

    func parse(url: URL) throws -> EPUBBook {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try unzipEPUB(from: url, to: tempDir)

        let opfFile = try findOPFFile(in: tempDir)
        return try parseOPF(file: opfFile)
    }

    // MARK: - ZIP 解压

    private func unzipEPUB(from source: URL, to destination: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", "-q", source.path, "-d", destination.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw EPUBError.cannotUnzip }
    }

    // MARK: - OPF 定位

    private func findOPFFile(in directory: URL) throws -> URL {
        let containerURL = directory.appendingPathComponent("META-INF/container.xml")
        let containerData = try Data(contentsOf: containerURL)
        let containerXML = try XMLDocument(data: containerData)

        if let rootfiles = try containerXML.nodes(forXPath: "//*[local-name()='rootfile']") as? [XMLElement],
           let rootfile = rootfiles.first,
           let fullPath = rootfile.attribute(forName: "full-path")?.stringValue {
            return directory.appendingPathComponent(fullPath)
        }

        throw EPUBError.invalidFormat
    }

    // MARK: - OPF 解析

    private func parseOPF(file: URL) throws -> EPUBBook {
        let data = try Data(contentsOf: file)
        let xml = try XMLDocument(data: data)
        let opfDir = file.deletingLastPathComponent()

        // 元数据
        let title = (try? xml.nodes(forXPath: "//*[local-name()='title']"))?.first?.stringValue ?? "未知标题"
        let creator = (try? xml.nodes(forXPath: "//*[local-name()='creator']"))?.first?.stringValue ?? "未知作者"

        // manifest: id → href
        var manifestItems: [String: String] = [:]
        if let items = try? xml.nodes(forXPath: "//*[local-name()='manifest']/*[local-name()='item']") as? [XMLElement] {
            for item in items {
                if let id = item.attribute(forName: "id")?.stringValue,
                   let href = item.attribute(forName: "href")?.stringValue {
                    manifestItems[id] = href
                }
            }
        }

        // spine: 阅读顺序
        var spineItems: [String] = []
        if let refs = try? xml.nodes(forXPath: "//*[local-name()='spine']/*[local-name()='itemref']") as? [XMLElement] {
            for ref in refs {
                if let idref = ref.attribute(forName: "idref")?.stringValue {
                    spineItems.append(idref)
                }
            }
        }

        // NCX 目录标题 (src → title)
        var ncxTitles: [String: String] = [:]
        if let ncxHref = findNCXHref(in: manifestItems, xml: xml) {
            let ncxURL = opfDir.appendingPathComponent(ncxHref)
            ncxTitles = parseNCXTitles(at: ncxURL)
        }

        // 加载章节
        var chapters: [EPUBChapter] = []
        for idref in spineItems {
            guard let href = manifestItems[idref] else { continue }
            let chapterURL = opfDir.appendingPathComponent(href)
            guard let content = try? String(contentsOf: chapterURL, encoding: .utf8) else { continue }

            // 用 NCX 标题匹配，找不到则从 HTML <title> 提取，最后用文件名
            let chapterTitle = matchNCXTitle(href: href, ncxTitles: ncxTitles)
                ?? extractHTMLTitle(from: content)
                ?? hrefToTitle(href)

            chapters.append(EPUBChapter(title: chapterTitle, content: content, fileName: href))
        }

        guard !chapters.isEmpty else { throw EPUBError.noContent }

        return EPUBBook(title: title, creator: creator, chapters: chapters)
    }

    // MARK: - NCX 解析

    private func findNCXHref(in manifest: [String: String], xml: XMLDocument) -> String? {
        // 方式1: spine 的 toc 属性指向 NCX id
        if let spines = try? xml.nodes(forXPath: "//*[local-name()='spine']") as? [XMLElement],
           let spine = spines.first,
           let tocId = spine.attribute(forName: "toc")?.stringValue,
           let href = manifest[tocId] {
            return href
        }
        // 方式2: manifest 中 media-type 为 ncx 的项
        for (_, href) in manifest where href.hasSuffix(".ncx") {
            return href
        }
        return nil
    }

    private func parseNCXTitles(at url: URL) -> [String: String] {
        guard let data = try? Data(contentsOf: url),
              let xml = try? XMLDocument(data: data) else { return [:] }

        var titles: [String: String] = [:]
        if let navPoints = try? xml.nodes(forXPath: "//*[local-name()='navPoint']") as? [XMLElement] {
            collectNavPointTitles(navPoints, into: &titles)
        }
        return titles
    }

    private func collectNavPointTitles(_ elements: [XMLElement], into titles: inout [String: String]) {
        for element in elements {
            let label = (try? element.nodes(forXPath: "*[local-name()='navLabel']/*[local-name()='text']"))?.first?.stringValue ?? ""
            if let contentEl = (try? element.nodes(forXPath: "*[local-name()='content']"))?.first as? XMLElement,
               let src = contentEl.attribute(forName: "src")?.stringValue,
               !label.isEmpty {
                // 去掉锚点 (chapter1.xhtml#section1 → chapter1.xhtml)
                let cleanSrc = src.components(separatedBy: "#").first ?? src
                // 只保留第一个匹配（章节标题），不让后续小节标题覆盖
                if titles[cleanSrc] == nil {
                    titles[cleanSrc] = label
                }
            }
            // 递归子节点
            if let children = try? element.nodes(forXPath: "*[local-name()='navPoint']") as? [XMLElement] {
                collectNavPointTitles(children, into: &titles)
            }
        }
    }

    private func matchNCXTitle(href: String, ncxTitles: [String: String]) -> String? {
        // 精确匹配
        if let title = ncxTitles[href] { return title }
        // 文件名匹配（NCX 中的 src 可能包含路径前缀）
        let fileName = URL(fileURLWithPath: href).lastPathComponent
        for (src, title) in ncxTitles {
            if URL(fileURLWithPath: src).lastPathComponent == fileName { return title }
        }
        return nil
    }

    private func extractHTMLTitle(from html: String) -> String? {
        guard let titleRange = html.range(of: "<title>"),
              let endRange = html.range(of: "</title>") else { return nil }
        let title = String(html[titleRange.upperBound..<endRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? nil : title
    }

    private func hrefToTitle(_ href: String) -> String {
        URL(fileURLWithPath: href).deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }

    // MARK: - HTML → NSAttributedString

    static func htmlToAttributedString(_ html: String, fontFamily: String, fontSize: CGFloat) -> NSAttributedString {
        // 注入基础样式，统一字体字号
        let styledHTML = """
        <html><head><style>
        body { font-family: '\(fontFamily)', sans-serif; font-size: \(fontSize)px;
               line-height: 1.6; color: #000; }
        h1 { font-size: \(fontSize * 2.0)px; }
        h2 { font-size: \(fontSize * 1.7)px; }
        h3 { font-size: \(fontSize * 1.4)px; }
        h4, h5, h6 { font-size: \(fontSize * 1.2)px; }
        pre, code { font-family: Menlo, monospace; font-size: \(fontSize * 0.9)px; }
        blockquote { color: #444; padding-left: 12px; border-left: 3px solid #ccc; }
        </style></head><body>\(html)</body></html>
        """

        guard let data = styledHTML.data(using: .utf8) else {
            return NSAttributedString(string: html)
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributed
        }

        return NSAttributedString(string: html)
    }
}
