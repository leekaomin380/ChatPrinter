//
//  PDFExportManager.swift
//  ChatPrinter
//
//  PDF 导出管理器
//

import AppKit
import PDFKit

class PDFExportManager {
    static let shared = PDFExportManager()

    private init() {}

    /// 导出 EPUB 为 PDF
    /// - Parameters:
    ///   - epubURL: EPUB 文件路径
    ///   - outputURL: 输出 PDF 路径
    ///   - progressHandler: 进度回调 (0.0 - 1.0)
    ///   - completion: 完成回调
    func exportEPUBToPDF(
        from epubURL: URL,
        to outputURL: URL,
        progressHandler: ((Double) -> Void)?,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            // 模拟进度
            for i in 0...10 {
                Thread.sleep(forTimeInterval: 0.1)
                progressHandler?(Double(i) / 10.0)
            }

            // 创建测试 PDF
            let success = self.createTestPDF(at: outputURL)

            DispatchQueue.main.async {
                completion(success, nil)
            }
        }
    }

    /// 创建测试 PDF（临时实现）
    private func createTestPDF(at url: URL) -> Bool {
        do {
            // 使用 PDFContext 创建空 PDF
            let pdfInfo: [String: Any] = [
                kCGPDFContextCreator as String: "ChatPrinter"
            ]
            let data = NSMutableData()
            guard let consumer = CGDataConsumer(data: data as CFMutableData) else { return false }
            guard let context = CGContext(consumer: consumer, mediaBox: nil, pdfInfo as CFDictionary) else { return false }
            context.beginPDFPage(nil)
            context.endPDFPage()
            context.closePDF()
            try data.write(to: url)
            return true
        } catch {
            return false
        }
    }

    /// 显示保存对话框
    func showSavePanel(completion: @escaping (URL?) -> Void) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "output.pdf"
        savePanel.canCreateDirectories = true
        savePanel.title = "导出 PDF"

        savePanel.begin { response in
            if response == .OK {
                completion(savePanel.url)
            } else {
                completion(nil)
            }
        }
    }
}
