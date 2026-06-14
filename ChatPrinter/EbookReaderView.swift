//
//  EbookReaderView.swift
//  ChatPrinter
//
//  电子书助手视图 - EPUB 预览、打印、PDF 导出
//

import SwiftUI
import AppKit
import Combine

// MARK: - Book State Manager

class EbookState: ObservableObject {
    @Published var book: EPUBParser.EPUBBook?
    @Published var selectedChapterIndex: Int = 0
    @Published var fontSize: CGFloat = 14
    @Published var fontFamily: String = "Helvetica"
    @Published var isLoading = false
    @Published var errorMessage: String?

    var currentChapter: EPUBParser.EPUBChapter? {
        guard let book = book, selectedChapterIndex < book.chapters.count else { return nil }
        return book.chapters[selectedChapterIndex]
    }

    func loadEPUB(url: URL) {
        isLoading = true
        errorMessage = nil
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let accessing = url.startAccessingSecurityScopedResource()
                let parser = EPUBParser()
                let book = try parser.parse(url: url)
                if accessing { url.stopAccessingSecurityScopedResource() }
                DispatchQueue.main.async {
                    self.book = book
                    self.selectedChapterIndex = 0
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Action Manager

class EbookActionManager: ObservableObject {
    enum Action: Equatable {
        case print
        case exportPDF
    }
    @Published var pendingAction: Action?
}

// MARK: - Main View

struct EbookReaderView: View {
    @StateObject private var state = EbookState()
    @StateObject private var actionManager = EbookActionManager()
    @State private var showImportPanel = false

    var body: some View {
        VStack(spacing: 0) {
            EbookToolbarView(state: state, actionManager: actionManager, showImportPanel: $showImportPanel)
            Divider()

            if state.isLoading {
                ProgressView("正在解析 EPUB...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let book = state.book {
                HSplitView {
                    // 章节目录
                    ChapterListView(chapters: book.chapters, selectedIndex: $state.selectedChapterIndex)
                        .frame(minWidth: 160, idealWidth: 200, maxWidth: 250)

                    // 内容预览
                    EbookContentView(state: state, actionManager: actionManager)
                }
            } else {
                EmptyEbookView(showImportPanel: $showImportPanel, errorMessage: state.errorMessage)
            }

            Divider()
            EbookStatusBarView(state: state)
        }
        .background(Color.white)
        .fileImporter(
            isPresented: $showImportPanel,
            allowedContentTypes: [.epub],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                state.loadEPUB(url: url)
            }
        }
    }
}

// MARK: - Toolbar

struct EbookToolbarView: View {
    @ObservedObject var state: EbookState
    @ObservedObject var actionManager: EbookActionManager
    @Binding var showImportPanel: Bool

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { showImportPanel = true }) {
                Label("导入 EPUB", systemImage: "square.and.arrow.down")
            }
            .keyboardShortcut("o", modifiers: .command)

            Button(action: { actionManager.pendingAction = .print }) {
                Label("打印", systemImage: "printer")
            }
            .keyboardShortcut("p", modifiers: .command)
            .disabled(state.book == nil)

            Divider()

            Button(action: { actionManager.pendingAction = .exportPDF }) {
                Label("导出 PDF", systemImage: "doc.badge.plus")
            }
            .keyboardShortcut("e", modifiers: .command)
            .disabled(state.book == nil)

            Divider()

            Menu {
                ForEach(["Helvetica", "STSong", "Times New Roman", "Georgia", "Courier New", "Arial"], id: \.self) { font in
                    Button(action: { state.fontFamily = font }) {
                        Text(font)
                        if state.fontFamily == font {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                Label("字体", systemImage: "textformat")
            }

            HStack(spacing: 4) {
                Button(action: { state.fontSize = max(8, state.fontSize - 1) }) {
                    Image(systemName: "textformat.size.smaller")
                }
                Text("\(Int(state.fontSize))pt").frame(width: 50).font(.system(.caption, design: .monospaced))
                Button(action: { state.fontSize = min(72, state.fontSize + 1) }) {
                    Image(systemName: "textformat.size.larger")
                }
            }

            Spacer()
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Chapter List

struct ChapterListView: View {
    let chapters: [EPUBParser.EPUBChapter]
    @Binding var selectedIndex: Int

    var body: some View {
        List(chapters.indices, id: \.self) { index in
            Text(chapters[index].title)
                .font(.system(.callout))
                .lineLimit(2)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .background(index == selectedIndex ? Color.accentColor.opacity(0.15) : Color.clear)
                .cornerRadius(4)
                .onTapGesture { selectedIndex = index }
        }
        .listStyle(.sidebar)
    }
}

// MARK: - Content View (NSViewRepresentable)

struct EbookContentView: NSViewRepresentable {
    @ObservedObject var state: EbookState
    @ObservedObject var actionManager: EbookActionManager

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer()

        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)

        textContainer.widthTracksTextView = true
        textContainer.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)

        let textView = NSTextView(frame: .zero, textContainer: textContainer)
        textView.autoresizingMask = [.width]
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = true
        textView.backgroundColor = NSColor.white
        textView.textContainerInset = NSSize(width: 20, height: 15)
        textView.isRichText = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textContainer.lineFragmentPadding = 10

        scrollView.documentView = textView

        let coordinator = context.coordinator
        coordinator.textView = textView

        // Combine 订阅 action
        coordinator.actionSubscription = actionManager.$pendingAction
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak coordinator] action in
                coordinator?.handleAction(action)
                actionManager.pendingAction = nil
            }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let coordinator = context.coordinator

        // 检查章节或字体是否变化
        let chapterID = state.currentChapter?.id
        let needsRerender = coordinator.lastChapterID != chapterID
            || coordinator.lastFontSize != state.fontSize
            || coordinator.lastFontFamily != state.fontFamily

        if needsRerender, let chapter = state.currentChapter {
            coordinator.lastChapterID = chapterID
            coordinator.lastFontSize = state.fontSize
            coordinator.lastFontFamily = state.fontFamily
            coordinator.book = state.book

            let html = chapter.content
            let family = state.fontFamily
            let size = state.fontSize

            DispatchQueue.global(qos: .userInitiated).async {
                let attributed = EPUBParser.htmlToAttributedString(html, fontFamily: family, fontSize: size)
                DispatchQueue.main.async {
                    coordinator.textView?.textStorage?.setAttributedString(attributed)
                    coordinator.textView?.scrollToBeginningOfDocument(nil)
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        var textView: NSTextView?
        var book: EPUBParser.EPUBBook?
        var actionSubscription: AnyCancellable?
        var lastChapterID: UUID?
        var lastFontSize: CGFloat = 0
        var lastFontFamily: String = ""

        func handleAction(_ action: EbookActionManager.Action) {
            switch action {
            case .print:
                handlePrint()
            case .exportPDF:
                handleExportPDF()
            }
        }

        private func handlePrint() {
            guard let tv = textView else { return }
            PrintManager.shared.printTextView(tv)
        }

        private func handleExportPDF() {
            guard let book = book else { return }
            PDFExportManager.shared.exportBook(book)
        }

        deinit {
            actionSubscription?.cancel()
        }
    }
}

// MARK: - Empty State

struct EmptyEbookView: View {
    @Binding var showImportPanel: Bool
    let errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("导入 EPUB 电子书")
                .font(.title2)
                .fontWeight(.semibold)

            Text("支持 EPUB 格式电子书\n导入后可预览、打印到电子纸或导出为 PDF")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 40)
            }

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

// MARK: - Status Bar

struct EbookStatusBarView: View {
    @ObservedObject var state: EbookState

    var body: some View {
        HStack {
            if let book = state.book {
                Text("\(book.title) — \(book.creator)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let chapter = state.currentChapter {
                    Text("第 \(state.selectedChapterIndex + 1)/\(book.chapters.count) 章：\(chapter.title)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("未选择文件")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("打印到电子纸 / 导出 PDF")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
