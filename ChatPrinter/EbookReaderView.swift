//
//  EbookReaderView.swift
//  ChatPrinter
//
//  电子书助手视图
//

import SwiftUI
import AppKit

struct EbookReaderView: View {
    @State private var showImportPanel = false
    @State private var epubFileURL: URL?
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var showProgressPanel = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            EbookReaderToolbarView(
                showImportPanel: $showImportPanel,
                isExporting: $isExporting,
                exportProgress: $exportProgress,
                showProgressPanel: $showProgressPanel
            )
            
            Divider()
            
            // 内容区域
            Group {
                if let fileURL = epubFileURL {
                    EPUBPreviewView(fileURL: fileURL)
                } else {
                    EmptyEbookView(showImportPanel: $showImportPanel)
                }
            }
            
            Divider()
            
            // 状态栏
            EbookStatusBarView(epubFileURL: epubFileURL)
        }
        .background(Color.white)
        .fileImporter(
            isPresented: $showImportPanel,
            allowedContentTypes: [.epub],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    // 获取文件访问权限
                    let accessing = url.startAccessingSecurityScopedResource()
                    epubFileURL = url
                    if accessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
            case .failure(let error):
                print("导入失败：\(error)")
            }
        }
    }
}

// MARK: - Toolbar

struct EbookReaderToolbarView: View {
    @Binding var showImportPanel: Bool
    @Binding var isExporting: Bool
    @Binding var exportProgress: Double
    @Binding var showProgressPanel: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // 导入按钮
            Button(action: { showImportPanel = true }) {
                Label("导入 EPUB", systemImage: "square.and.arrow.down")
            }
            .keyboardShortcut("o", modifiers: .command)
            
            // 打印按钮
            Button(action: {
                NotificationCenter.default.post(name: .printEPUB, object: nil)
            }) {
                Label("打印", systemImage: "printer")
            }
            .keyboardShortcut("p", modifiers: .command)
            .disabled(isExporting)
            
            Divider()
            
            // 导出 PDF 按钮
            Button(action: {
                NotificationCenter.default.post(name: .exportPDF, object: (isExporting, exportProgress, showProgressPanel))
            }) {
                Label("导出 PDF", systemImage: "doc.badge.plus")
            }
            .keyboardShortcut("e", modifiers: .command)
            .disabled(isExporting)
            
            // 进度指示器
            if isExporting {
                HStack(spacing: 8) {
                    ProgressView(value: exportProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 100)
                    
                    Text("\(Int(exportProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Empty State

struct EmptyEbookView: View {
    @Binding var showImportPanel: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.purple)
            
            Text("导入 EPUB 电子书")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("支持 EPUB 格式电子书\n导入后可预览并打印到电子纸")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showImportPanel = true }) {
                Text("选择文件")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - EPUB Preview

struct EPUBPreviewView: View {
    let fileURL: URL
    @State private var bookInfo: String = "正在解析..."

    var body: some View {
        ScrollView {
            Text(bookInfo)
                .font(.system(.body, design: .monospaced))
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear { parseEPUB() }
        .onChange(of: fileURL) { _ in parseEPUB() }
    }

    private func parseEPUB() {
        do {
            let book = try EPUBParser().parse(url: fileURL)
            var info = "书名：\(book.title)\n作者：\(book.creator)\n章节数：\(book.chapters.count)\n"
            info += "\n--- 目录 ---\n"
            for (i, chapter) in book.chapters.enumerated() {
                info += "\(i + 1). \(chapter.title)\n"
            }
            bookInfo = info
        } catch {
            bookInfo = "解析失败：\(error.localizedDescription)"
        }
    }
}

// MARK: - Status Bar

struct EbookStatusBarView: View {
    let epubFileURL: URL?
    
    var body: some View {
        HStack {
            if let url = epubFileURL {
                Text("当前：\(url.lastPathComponent)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("未选择文件")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("打印到电子纸 / 导出 PDF")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Notification Names

// 通知名称已在 ChatPrinterApp.swift 中统一一定义
