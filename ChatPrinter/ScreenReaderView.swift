//
//  ScreenReaderView.swift
//  ChatPrinter
//
//  屏幕阅读助手视图
//

import SwiftUI
import AppKit
import Combine

// MARK: - Action Manager

class EditorActionManager: ObservableObject {
    enum Action: Equatable {
        case paste(String)
        case print
        case newDocument
        case renderMarkdown
    }

    @Published var pendingAction: Action?
}

// MARK: - Parent View

struct ScreenReaderView: View {
    @State private var fontSize: CGFloat = 14
    @State private var text = ""
    @State private var fontFamily: String = "Helvetica"
    @StateObject private var actionManager = EditorActionManager()

    var body: some View {
        VStack(spacing: 0) {
            ScreenReaderToolbarView(fontSize: $fontSize, fontFamily: $fontFamily, actionManager: actionManager)
            Divider()
            ScreenReaderTextView(text: $text, fontSize: $fontSize, fontFamily: $fontFamily, actionManager: actionManager)
            Divider()
            ScreenReaderStatusBar(characterCount: text.count)
        }
        .background(Color.white)
    }
}

// MARK: - Toolbar

struct ScreenReaderToolbarView: View {
    @Binding var fontSize: CGFloat
    @Binding var fontFamily: String
    @ObservedObject var actionManager: EditorActionManager

    var body: some View {
        HStack(spacing: 12) {
            Button(action: pasteFromClipboard) {
                Label("粘贴", systemImage: "doc.on.clipboard")
            }
            .keyboardShortcut("v", modifiers: .command)

            Button(action: { actionManager.pendingAction = .print }) {
                Label("打印", systemImage: "printer")
            }
            .keyboardShortcut("p", modifiers: .command)

            Divider()

            Button(action: { actionManager.pendingAction = .renderMarkdown }) {
                Label("渲染 MD", systemImage: "textformat.abc")
            }

            Divider()

            Menu {
                ForEach(["Helvetica", "STSong", "Times New Roman", "Georgia", "Courier New", "Arial"], id: \.self) { font in
                    Button(action: { fontFamily = font }) {
                        Text(font)
                        if fontFamily == font {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                Label("字体", systemImage: "textformat")
            }

            HStack(spacing: 4) {
                Button(action: { fontSize = max(8, fontSize - 1) }) {
                    Image(systemName: "textformat.size.smaller")
                }
                Text("\(Int(fontSize))pt").frame(width: 50).font(.system(.caption, design: .monospaced))
                Button(action: { fontSize = min(72, fontSize + 1) }) {
                    Image(systemName: "textformat.size.larger")
                }
            }

            Spacer()

            Button(action: { actionManager.pendingAction = .newDocument }) {
                Label("清除", systemImage: "trash")
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func pasteFromClipboard() {
        if let pasteboard = NSPasteboard.general.string(forType: .string) {
            actionManager.pendingAction = .paste(pasteboard)
        }
    }
}

// MARK: - NSViewRepresentable Text View

struct ScreenReaderTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var fontSize: CGFloat
    @Binding var fontFamily: String
    @ObservedObject var actionManager: EditorActionManager

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
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = true
        textView.backgroundColor = NSColor.white
        textView.textContainerInset = NSSize(width: 20, height: 15)
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textContainer.lineFragmentPadding = 10

        let font = NSFont(name: fontFamily, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        textView.font = font
        textView.textColor = NSColor.black

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.5
        paragraphStyle.paragraphSpacing = 8
        textView.defaultParagraphStyle = paragraphStyle

        scrollView.documentView = textView

        let coordinator = context.coordinator
        coordinator.textView = textView
        coordinator.fontSize = fontSize
        coordinator.fontFamily = fontFamily

        // Combine 订阅：Coordinator 直接响应 action 变化
        coordinator.actionSubscription = actionManager.$pendingAction
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak coordinator] action in
                coordinator?.handleAction(action)
                actionManager.pendingAction = nil
            }

        // App 菜单栏的通知（跨组件通信，保留 NotificationCenter）
        NotificationCenter.default.addObserver(
            coordinator,
            selector: #selector(coordinator.handleMenuPrint(_:)),
            name: .printDocument, object: nil)
        NotificationCenter.default.addObserver(
            coordinator,
            selector: #selector(coordinator.handleMenuNew(_:)),
            name: .newDocument, object: nil)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let coordinator = context.coordinator
        coordinator.fontSize = fontSize
        coordinator.fontFamily = fontFamily

        // 只在非富文本渲染状态下更新字体
        if !coordinator.isRendered, let textView = scrollView.documentView as? NSTextView {
            let font = NSFont(name: fontFamily, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
            textView.font = font
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ScreenReaderTextView
        var textView: NSTextView?
        var fontSize: CGFloat = 14
        var fontFamily: String = "Helvetica"
        var isRendered = false
        var actionSubscription: AnyCancellable?

        init(_ parent: ScreenReaderTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = textView else { return }
            parent.text = tv.string
            isRendered = false
        }

        func handleAction(_ action: EditorActionManager.Action) {
            switch action {
            case .paste(let newText):
                handlePaste(newText)
            case .print:
                handlePrint()
            case .newDocument:
                handleNewDocument()
            case .renderMarkdown:
                handleRenderMarkdown()
            }
        }

        private func handlePaste(_ newText: String) {
            guard let tv = textView else { return }
            let currentText = tv.string
            tv.string = currentText.isEmpty ? newText : currentText + "\n\n" + newText
            tv.didChangeText()
        }

        private func handlePrint() {
            guard let tv = textView else { return }
            PrintManager.shared.printTextView(tv)
        }

        private func handleNewDocument() {
            guard let tv = textView else { return }
            tv.string = ""
            tv.didChangeText()
            isRendered = false
        }

        private func handleRenderMarkdown() {
            guard let tv = textView, !tv.string.isEmpty else { return }

            let sourceText = tv.string
            let family = fontFamily
            let size = fontSize

            DispatchQueue.global(qos: .userInitiated).async {
                let attributedString = MarkdownRenderer.render(sourceText, fontFamily: family, fontSize: size)

                DispatchQueue.main.async { [weak self] in
                    tv.textStorage?.setAttributedString(attributedString)
                    tv.didChangeText()
                    self?.isRendered = true
                    self?.parent.text = tv.string
                }
            }
        }

        @objc func handleMenuPrint(_ notification: Notification) {
            handlePrint()
        }

        @objc func handleMenuNew(_ notification: Notification) {
            handleNewDocument()
        }

        deinit {
            actionSubscription?.cancel()
            NotificationCenter.default.removeObserver(self)
        }
    }
}

// MARK: - Status Bar

struct ScreenReaderStatusBar: View {
    let characterCount: Int

    var body: some View {
        HStack {
            Text("字符数：\(characterCount)").font(.caption).foregroundColor(.secondary)
            Spacer()
            Text("打印到电子纸").font(.caption).foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
