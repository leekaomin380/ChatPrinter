//
//  EPUBParser.swift
//  ChatPrinter
//
//  EPUB 解析器 - 使用原生 ZIP/XML 解析
//

import Foundation
import AppKit
import PDFKit

class EPUBParser {
    
    enum EPUBError: Error {
        case invalidFormat
        case cannotUnzip
        case noContent
    }
    
    struct EPUBBook {
        var title: String
        var creator: String
        var chapters: [EPUBChapter]
        var ncxItems: [NCXItem]
    }
    
    struct EPUBChapter {
        var title: String
        var content: String
        var fileName: String
    }
    
    struct NCXItem {
        var title: String
        var src: String
        var playOrder: String
    }
    
    /// 解析 EPUB 文件
    /// - Parameter url: EPUB 文件路径
    /// - Returns: EPUBBook 对象
    func parse(url: URL) throws -> EPUBBook {
        // EPUB 本质是 ZIP 文件
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // 解压 EPUB
        try unzipEPUB(from: url, to: tempDir)
        
        // 解析 OPF 文件获取元数据和章节
        let opfFile = try findOPFFile(in: tempDir)
        let metadata = try parseOPF(file: opfFile, basePath: tempDir)
        
        // 清理临时文件
        try? FileManager.default.removeItem(at: tempDir)
        
        return metadata
    }
    
    /// 解压 EPUB 文件
    private func unzipEPUB(from source: URL, to destination: URL) throws {
        // 使用 Process 调用系统 unzip 命令
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", "-q", source.path, "-d", destination.path]
        try process.run()
        process.waitUntilExit()
    }
    
    /// 查找 OPF 文件
    private func findOPFFile(in directory: URL) throws -> URL {
        // 首先查找 container.xml
        let containerURL = directory.appendingPathComponent("META-INF/container.xml")
        let containerData = try Data(contentsOf: containerURL)
        let containerXML = try XMLDocument(data: containerData)
        
        // 获取 rootfile 的 full-path
        if let rootfiles = try containerXML.nodes(forXPath: "//rootfile") as? [XMLElement],
           let rootfile = rootfiles.first,
           let fullPath = rootfile.attribute(forName: "full-path")?.stringValue {
            return directory.appendingPathComponent(fullPath)
        }
        
        throw EPUBError.invalidFormat
    }
    
    /// 解析 OPF 文件
    private func parseOPF(file: URL, basePath: URL) throws -> EPUBBook {
        let data = try Data(contentsOf: file)
        let xml = try XMLDocument(data: data)
        
        // 解析元数据
        var title = "未知标题"
        var creator = "未知作者"
        
        if let titles = try xml.nodes(forXPath: "//metadata/dc:title") as? [XMLElement],
           let titleElement = titles.first {
            title = titleElement.stringValue ?? "未知标题"
        }
        
        if let creators = try xml.nodes(forXPath: "//metadata/dc:creator") as? [XMLElement],
           let creatorElement = creators.first {
            creator = creatorElement.stringValue ?? "未知作者"
        }
        
        // 解析 manifest 获取所有文件
        var manifestItems: [String: String] = [:] // id -> href
        if let manifests = try xml.nodes(forXPath: "//manifest/item") as? [XMLElement] {
            for item in manifests {
                if let id = item.attribute(forName: "id")?.stringValue,
                   let href = item.attribute(forName: "href")?.stringValue {
                    manifestItems[id] = href
                }
            }
        }
        
        // 解析 spine 获取阅读顺序
        var spineItems: [String] = []
        if let spines = try xml.nodes(forXPath: "//spine/itemref") as? [XMLElement] {
            for item in spines {
                if let idref = item.attribute(forName: "idref")?.stringValue {
                    spineItems.append(idref)
                }
            }
        }
        
        // 解析 NCX 目录
        var ncxItems: [NCXItem] = []
        if let navMaps = try xml.nodes(forXPath: "//navMap/navPoint") as? [XMLElement] {
            ncxItems = parseNavPoints(navMaps)
        }
        
        // 加载章节内容
        var chapters: [EPUBChapter] = []
        for idref in spineItems {
            if let href = manifestItems[idref] {
                let chapterURL = file.deletingLastPathComponent().appendingPathComponent(href)
                do {
                    let content = try String(contentsOf: chapterURL, encoding: .utf8)
                    chapters.append(EPUBChapter(
                        title: href,
                        content: content,
                        fileName: href
                    ))
                } catch {
                    print("无法加载章节：\(href)")
                }
            }
        }
        
        return EPUBBook(
            title: title,
            creator: creator,
            chapters: chapters,
            ncxItems: ncxItems
        )
    }
    
    /// 解析 NCX 导航点
    private func parseNavPoints(_ elements: [XMLElement], parent: String = "") -> [NCXItem] {
        var items: [NCXItem] = []
        
        for element in elements {
            var title = ""
            var src = ""
            var playOrder = ""
            
            if let label = try? element.nodes(forXPath: "navLabel/labelText").first as? XMLElement {
                title = label.stringValue ?? ""
            }
            
            if let content = try? element.nodes(forXPath: "content").first as? XMLElement,
               let contentSrc = content.attribute(forName: "src")?.stringValue {
                src = contentSrc
            }
            
            if let playOrderAttr = element.attribute(forName: "playOrder")?.stringValue {
                playOrder = playOrderAttr
            }
            
            if !src.isEmpty {
                items.append(NCXItem(title: title, src: src, playOrder: playOrder))
            }
            
            // 递归解析子导航点
            if let childNavPoints = try? element.nodes(forXPath: "navPoint") as? [XMLElement] {
                items.append(contentsOf: parseNavPoints(childNavPoints, parent: title))
            }
        }
        
        return items
    }
    
    /// 导出为 PDF（简化版本 - 占位实现）
    func exportToPDF(book: EPUBBook, to url: URL, progressHandler: ((Double) -> Void)?, completion: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // 模拟进度
            for i in 0...10 {
                Thread.sleep(forTimeInterval: 0.05)
                progressHandler?(Double(i) / 10.0)
            }
            
            // 创建空 PDF 作为占位
            // TODO: 未来版本实现完整的 EPUB 到 PDF 转换
            let pdfInfo: [String: Any] = [
                kCGPDFContextCreator as String: "ChatPrinter",
                kCGPDFContextTitle as String: book.title
            ]
            
            let data = NSMutableData()
            guard let consumer = CGDataConsumer(data: data as CFMutableData) else {
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }
            
            guard let context = CGContext(consumer: consumer, mediaBox: nil, pdfInfo as CFDictionary) else {
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }
            
            // 添加封面页
            context.beginPDFPage(nil)
            context.endPDFPage()
            
            context.closePDF()
            
            do {
                try data.write(to: url)
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, error)
                }
            }
        }
    }
}
