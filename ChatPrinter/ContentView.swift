//
//  ContentView.swift
//  ChatPrinter
//

import SwiftUI
import AppKit
import NaturalLanguage

struct ContentView: View {
    @State private var fontSize: CGFloat = 14
    @State private var text = ""
    @State private var fontFamily: String = "Helvetica"
    @State private var showFontPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            ToolbarView(
                fontSize: $fontSize,
                fontFamily: $fontFamily,
                showFontPicker: $showFontPicker
            )

            Divider()

            // 文本编辑区域
            TextEditorView(text: $text, fontSize: $fontSize, fontFamily: $fontFamily)

            Divider()

            // 状态栏
            StatusBarView(characterCount: text.count)
        }
        .background(Color.white)
        .onReceive(NotificationCenter.default.publisher(for: .newDocument)) { _ in
            text = ""
        }
        .onReceive(NotificationCenter.default.publisher(for: .printDocument)) { _ in
            // 打印由 TextEditorView 内部处理
        }
    }
}

// MARK: - Toolbar

struct ToolbarView: View {
    @Binding var fontSize: CGFloat
    @Binding var fontFamily: String
    @Binding var showFontPicker: Bool

    var body: some View {
        HStack(spacing: 12) {
            // 粘贴按钮
            Button(action: pasteFromClipboard) {
                Label("粘贴", systemImage: "doc.on.clipboard")
            }
            .keyboardShortcut("v", modifiers: .command)

            // 打印按钮
            Button(action: {
                NotificationCenter.default.post(name: .printDocument, object: nil)
            }) {
                Label("打印", systemImage: "printer")
            }
            .keyboardShortcut("p", modifiers: .command)

            Divider()

            // Markdown 渲染按钮
            Button(action: {
                NotificationCenter.default.post(name: .renderMarkdown, object: nil)
            }) {
                Label("渲染 MD", systemImage: "textformat.abc")
            }
            .help("渲染 Markdown 格式")

            Divider()

            // 字体选择
            Menu {
                ForEach(["Helvetica", "Times New Roman", "Georgia", "Courier New", "Arial"], id: \.self) { font in
                    Button(action: {
                        fontFamily = font
                    }) {
                        Text(font)
                            .font(.system(.body, design: font == "Courier New" ? .monospaced : .default))
                        if fontFamily == font {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                Label("字体", systemImage: "textformat")
            }

            // 字体大小调节
            HStack(spacing: 4) {
                Button(action: {
                    fontSize = max(8, fontSize - 1)
                }) {
                    Image(systemName: "textformat.size.smaller")
                }

                Text("\(Int(fontSize))pt")
                    .frame(width: 50)
                    .font(.system(.caption, design: .monospaced))

                Button(action: {
                    fontSize = min(72, fontSize + 1)
                }) {
                    Image(systemName: "textformat.size.larger")
                }
            }

            Spacer()

            // 清除按钮
            Button(action: {
                NotificationCenter.default.post(name: .newDocument, object: nil)
            }) {
                Label("清除", systemImage: "trash")
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func pasteFromClipboard() {
        if let pasteboard = NSPasteboard.general.string(forType: .string) {
            NotificationCenter.default.post(name: .pasteText, object: pasteboard)
        }
    }
}

// MARK: - Text Editor

struct TextEditorView: View {
    @Binding var text: String
    @Binding var fontSize: CGFloat
    @Binding var fontFamily: String

    var body: some View {
        SwiftUITextViewWrapper(text: $text, fontSize: $fontSize, fontFamily: $fontFamily)
    }
}

struct SwiftUITextViewWrapper: NSViewRepresentable {
    @Binding var text: String
    @Binding var fontSize: CGFloat
    @Binding var fontFamily: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // 创建文本视图
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

        // 打印优化样式
        let font = NSFont(name: fontFamily, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        textView.font = font
        textView.textColor = NSColor.black

        // 段落样式：1.5 倍行距
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.5
        paragraphStyle.paragraphSpacing = 8
        textView.defaultParagraphStyle = paragraphStyle

        scrollView.documentView = textView
        context.coordinator.textView = textView

        // 监听通知
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(context.coordinator.handlePaste(_:)),
            name: .pasteText,
            object: nil
        )

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(context.coordinator.handlePrint(_:)),
            name: .printDocument,
            object: nil
        )

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(context.coordinator.handleNew(_:)),
            name: .newDocument,
            object: nil
        )

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(context.coordinator.handleRenderMarkdown(_:)),
            name: .renderMarkdown,
            object: nil
        )

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = context.coordinator.textView {
            let font = NSFont(name: fontFamily, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
            textView.font = font
            
            // 更新滚动视图
            textView.minSize = NSSize(width: 0, height: 0)
            textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            textView.isVerticallyResizable = true
            textView.isHorizontallyResizable = false
            textView.autoresizingMask = [.width]
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SwiftUITextViewWrapper
        weak var textView: NSTextView?

        init(_ parent: SwiftUITextViewWrapper) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            parent.text = textView?.string ?? ""
        }

        @objc func handlePaste(_ notification: Notification) {
            guard let newText = notification.object as? String,
                  let textView = textView else { return }

            let currentText = textView.string
            if currentText.isEmpty {
                textView.string = newText
            } else {
                textView.string = currentText + "\n\n" + newText
            }
            textView.didChangeText()
            parent.text = textView.string
        }

        @objc func handlePrint(_ notification: Notification) {
            guard let textView = textView else { return }
            PrintManager.shared.printTextView(textView)
        }

        @objc func handleNew(_ notification: Notification) {
            textView?.string = ""
            parent.text = ""
        }

        @objc func handleRenderMarkdown(_ notification: Notification) {
            guard let textView = textView, !textView.string.isEmpty else { return }
            
            let attributedString = renderMarkdown(textView.string)
            textView.textStorage?.setAttributedString(attributedString)
            parent.text = textView.string
        }

        /// 渲染 Markdown 格式
        private func renderMarkdown(_ markdown: String) -> NSAttributedString {
            let attributedString = NSMutableAttributedString(string: markdown)
            let font = NSFont(name: parent.fontFamily, size: parent.fontSize) ?? NSFont.systemFont(ofSize: parent.fontSize)
            let boldFont = NSFont(name: parent.fontFamily, size: parent.fontSize) ?? NSFont.boldSystemFont(ofSize: parent.fontSize)
            let codeFont = NSFont(name: "Menlo", size: parent.fontSize) ?? NSFont.monospacedSystemFont(ofSize: parent.fontSize, weight: .regular)

            // 全文档基础样式
            attributedString.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(.foregroundColor, value: NSColor.black, range: NSRange(location: 0, length: attributedString.length))

            // 渲染标题 (# ## ###)
            let headerPatterns = [
                ("^### (.+)$", 1.4),
                ("^## (.+)$", 1.6),
                ("^# (.+)$", 1.8)
            ]

            for (pattern, sizeMultiplier) in headerPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) {
                    let matches = regex.matches(in: markdown, range: NSRange(markdown.startIndex..., in: markdown))
                    for match in matches.reversed() {
                        if let range = Range(match.range(at: 1), in: markdown) {
                            let nsRange = NSRange(range, in: attributedString.string)
                            let headerFont = NSFont(name: parent.fontFamily, size: parent.fontSize * sizeMultiplier) ?? NSFont.boldSystemFont(ofSize: parent.fontSize * sizeMultiplier)
                            attributedString.addAttribute(.font, value: headerFont, range: nsRange)
                            attributedString.addAttribute(.font, value: headerFont, range: NSRange(location: match.range.location, length: match.range.length))
                        }
                    }
                }
            }

            // 渲染粗体 (**text**)
            if let boldRegex = try? NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*", options: []) {
                let matches = boldRegex.matches(in: markdown, range: NSRange(markdown.startIndex..., in: markdown))
                for match in matches.reversed() {
                    if let contentRange = Range(match.range(at: 1), in: markdown) {
                        let nsRange = NSRange(contentRange, in: attributedString.string)
                        attributedString.addAttribute(.font, value: boldFont, range: nsRange)
                    }
                    // 移除 ** 标记
                    let fullRange = Range(match.range, in: markdown)
                    if let fullRange = fullRange {
                        let fullNsRange = NSRange(fullRange, in: attributedString.string)
                        attributedString.replaceCharacters(in: fullNsRange, with: String(markdown[fullRange]).replacingOccurrences(of: "**", with: ""))
                    }
                }
            }

            // 渲染斜体 (*text*)
            if let italicRegex = try? NSRegularExpression(pattern: "\\*(?!\\*)(.+?)\\*(?!\\*)", options: []) {
                let matches = italicRegex.matches(in: markdown, range: NSRange(markdown.startIndex..., in: markdown))
                for match in matches.reversed() {
                    if let contentRange = Range(match.range(at: 1), in: markdown) {
                        let nsRange = NSRange(contentRange, in: attributedString.string)
                        // 使用斜体字体
                        let italicFont = NSFont.systemFont(ofSize: parent.fontSize, weight: .regular)
                        attributedString.addAttribute(.font, value: italicFont, range: nsRange)
                        attributedString.addAttribute(.obliqueness, value: 0.2, range: nsRange)
                    }
                }
            }

            // 渲染行内代码 (`code`)
            if let codeRegex = try? NSRegularExpression(pattern: "`` (.+?) ``", options: []) {
                let matches = codeRegex.matches(in: markdown, range: NSRange(markdown.startIndex..., in: markdown))
                for match in matches.reversed() {
                    if let contentRange = Range(match.range(at: 1), in: markdown) {
                        let nsRange = NSRange(contentRange, in: attributedString.string)
                        attributedString.addAttribute(.font, value: codeFont, range: nsRange)
                        attributedString.addAttribute(.backgroundColor, value: NSColor.lightGray.withAlphaComponent(0.2), range: nsRange)
                    }
                }
            }

            return attributedString
        }
    }
}

// MARK: - Status Bar

struct StatusBarView: View {
    let characterCount: Int

    var body: some View {
        HStack {
            Text("字符数：\(characterCount)")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text("打印到电子纸")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let pasteText = Notification.Name("pasteText")
    static let renderMarkdown = Notification.Name("renderMarkdown")
}
