//
//  PDFExportManager.swift
//  ChatPrinter
//
//  PDF 导出管理器 - 将 EPUB 章节渲染为 PDF
//

import AppKit

class PDFExportManager {
    static let shared = PDFExportManager()

    private init() {}

    /// 导出整本书为 PDF（带保存对话框）
    func exportBook(_ book: EPUBParser.EPUBBook) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "\(book.title).pdf"
        savePanel.canCreateDirectories = true
        savePanel.title = "导出 PDF"

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            self.renderBookToPDF(book, to: url)
        }
    }

    /// 将所有章节渲染为 PDF 文件
    private func renderBookToPDF(_ book: EPUBParser.EPUBBook, to outputURL: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            // 在主线程创建所有 attributed strings（NSAttributedString HTML 解析需要主线程）
            var chapterContents: [NSAttributedString] = []

            let group = DispatchGroup()
            group.enter()
            DispatchQueue.main.async {
                for chapter in book.chapters {
                    let attributed = EPUBParser.htmlToAttributedString(
                        chapter.content, fontFamily: "Helvetica", fontSize: 12
                    )
                    chapterContents.append(attributed)
                }
                group.leave()
            }
            group.wait()

            // 合并所有章节
            let fullContent = NSMutableAttributedString()
            for (index, content) in chapterContents.enumerated() {
                if index > 0 {
                    fullContent.append(NSAttributedString(string: "\n\n"))
                }
                // 添加章节标题
                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 18),
                    .foregroundColor: NSColor.black
                ]
                let titleString = NSAttributedString(
                    string: "\(book.chapters[index].title)\n\n",
                    attributes: titleAttrs
                )
                fullContent.append(titleString)
                fullContent.append(content)
            }

            // 用 NSTextView 渲染到 PDF
            DispatchQueue.main.async {
                self.renderAttributedStringToPDF(fullContent, outputURL: outputURL, title: book.title)
            }
        }
    }

    /// 将 NSAttributedString 渲染为 PDF
    private func renderAttributedStringToPDF(_ content: NSAttributedString, outputURL: URL, title: String) {
        // A4 尺寸（点）: 595 x 842
        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 50
        let textWidth = pageWidth - margin * 2
        let textHeight = pageHeight - margin * 2

        // 创建 text layout
        let textStorage = NSTextStorage(attributedString: content)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        // 计算需要多少页
        var textContainers: [NSTextContainer] = []
        var pageCount = 0

        repeat {
            let textContainer = NSTextContainer(size: NSSize(width: textWidth, height: textHeight))
            layoutManager.addTextContainer(textContainer)
            textContainers.append(textContainer)
            pageCount += 1

            // 检查是否还有更多文字需要排版
            let glyphRange = layoutManager.glyphRange(for: textContainer)
            let lastGlyph = NSMaxRange(glyphRange)
            if lastGlyph >= layoutManager.numberOfGlyphs { break }
            if pageCount > 1000 { break } // 安全限制
        } while true

        // 创建 PDF
        let pdfData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            showAlert("PDF 创建失败")
            return
        }

        for textContainer in textContainers {
            context.beginPDFPage(nil)
            context.saveGState()

            // Core Graphics 原点在左下角(Y向上)，文本绘制需要左上角(Y向下)
            // 1. 移动原点到页面左上角
            // 2. 翻转 Y 轴
            // 3. 偏移到边距位置
            context.translateBy(x: 0, y: pageHeight)
            context.scaleBy(x: 1.0, y: -1.0)

            let nsContext = NSGraphicsContext(cgContext: context, flipped: true)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = nsContext

            let glyphRange = layoutManager.glyphRange(for: textContainer)
            let origin = NSPoint(x: margin, y: margin)
            layoutManager.drawBackground(forGlyphRange: glyphRange, at: origin)
            layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: origin)

            NSGraphicsContext.restoreGraphicsState()
            context.restoreGState()
            context.endPDFPage()
        }

        context.closePDF()

        do {
            try pdfData.write(to: outputURL)
            showAlert("导出成功", informative: "PDF 已保存到：\(outputURL.path)\n共 \(textContainers.count) 页", style: .informational)
        } catch {
            showAlert("保存失败：\(error.localizedDescription)")
        }
    }

    private func showAlert(_ message: String, informative: String = "", style: NSAlert.Style = .warning) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informative
        alert.alertStyle = style
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
}
