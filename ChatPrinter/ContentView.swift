//
//  ContentView.swift
//  ChatPrinter
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var fontSize: CGFloat = 12
    @State private var text = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            ToolbarView(fontSize: $fontSize)
            
            Divider()
            
            // 文本编辑区域
            TextEditorView(text: $text, fontSize: $fontSize)
            
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
            
            // 字体大小调节
            HStack(spacing: 4) {
                Button(action: {
                    fontSize = max(8, fontSize - 1)
                }) {
                    Image(systemName: "textformat.size.smaller")
                }
                
                Text("\(Int(fontSize))pt")
                    .frame(width: 40)
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
    
    var body: some View {
        SwiftUITextViewWrapper(text: $text, fontSize: $fontSize)
    }
}

struct SwiftUITextViewWrapper: NSViewRepresentable {
    @Binding var text: String
    @Binding var fontSize: CGFloat
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        
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
        
        // 打印优化样式
        textView.font = NSFont.systemFont(ofSize: fontSize)
        textView.textColor = NSColor.black
        
        // 段落样式：1.5 倍行距
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.5
        textView.defaultParagraphStyle = paragraphStyle
        
        scrollView.documentView = textView
        context.coordinator.textView = textView
        
        // 监听粘贴通知
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(context.coordinator.handlePaste(_:)),
            name: .pasteText,
            object: nil
        )
        
        // 监听打印通知
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(context.coordinator.handlePrint(_:)),
            name: .printDocument,
            object: nil
        )
        
        // 监听新建通知
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(context.coordinator.handleNew(_:)),
            name: .newDocument,
            object: nil
        )
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = context.coordinator.textView {
            textView.font = NSFont.systemFont(ofSize: fontSize)
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
}
