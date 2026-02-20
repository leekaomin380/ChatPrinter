//
//  ContentView.swift
//  ChatPrinter
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var fontSize: CGFloat = 12
    @State private var wordCount: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            ToolbarView(fontSize: $fontSize)
            
            Divider()
            
            // 文本编辑区域
            TextEditorView(fontSize: $fontSize, wordCount: $wordCount)
            
            Divider()
            
            // 状态栏
            StatusBarView(wordCount: wordCount)
        }
        .background(Color.white)
        .onReceive(NotificationCenter.default.publisher(for: .newDocument)) { _ in
            clearText()
        }
        .onReceive(NotificationCenter.default.publisher(for: .printDocument)) { _ in
            printDocument()
        }
    }
    
    private func clearText() {
        if let textView = NSApp.keyWindow?.contentView?.firstSubview(where: { $0 is NSTextView }) as? NSTextView {
            textView.string = ""
        }
    }
    
    private func printDocument() {
        if let textView = NSApp.keyWindow?.contentView?.firstSubview(where: { $0 is NSTextView }) as? NSTextView {
            PrintManager.shared.printTextView(textView)
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
                Button(action: decreaseFontSize) {
                    Image(systemName: "textformat.size.smaller")
                }
                
                Text("\(Int(fontSize))pt")
                    .frame(width: 40)
                    .font(.system(.caption, monospaced: true))
                
                Button(action: increaseFontSize) {
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
        if let pasteboard = NSPasteboard.general.string(forType: .string),
           let textView = NSApp.keyWindow?.contentView?.firstSubview(where: { $0 is NSTextView }) as? NSTextView {
            let currentText = textView.string
            if currentText.isEmpty {
                textView.string = pasteboard
            } else {
                textView.string = currentText + "\n\n" + pasteboard
            }
            textView.didChangeText()
        }
    }
    
    private func decreaseFontSize() {
        fontSize = max(8, fontSize - 1)
        updateTextViewFont()
    }
    
    private func increaseFontSize() {
        fontSize = min(72, fontSize + 1)
        updateTextViewFont()
    }
    
    private func updateTextViewFont() {
        if let textView = NSApp.keyWindow?.contentView?.firstSubview(where: { $0 is NSTextView }) as? NSTextView {
            textView.font = NSFont.systemFont(ofSize: fontSize)
        }
    }
}

// MARK: - Text Editor

struct TextEditorView: View {
    @Binding var fontSize: CGFloat
    @Binding var wordCount: Int
    
    var body: some View {
        GeometryReader { geometry in
            SwiftUITextViewWrapper(fontSize: fontSize, wordCount: $wordCount)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

class SwiftUITextViewWrapper: NSView {
    private var textView: NSTextView!
    private var scrollView: NSScrollView!
    @Binding var fontSize: CGFloat
    @Binding var wordCount: Int
    
    init(fontSize: Binding<CGFloat>, wordCount: Binding<Int>) {
        _fontSize = fontSize
        _wordCount = wordCount
        super.init(frame: .zero)
        setupTextView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTextView() {
        // 创建滚动视图
        scrollView = NSScrollView()
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
        textContainer.containerSize = NSSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        
        textView = NSTextView(frame: .zero, textContainer: textContainer)
        textView.autoresizingMask = [.width]
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = true
        textView.backgroundColor = NSColor.white
        textView.textContainerInset = NSSize(width: 20, height: 15)
        
        // 打印优化样式
        textView.font = NSFont.systemFont(ofSize: fontSize)
        textView.textColor = NSColor.black
        
        // 段落样式：1.5 倍行距
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.5
        paragraphStyle.headIndent = 0
        paragraphStyle.tailIndent = 0
        
        textView.defaultParagraphStyle = paragraphStyle
        
        // 代理用于字数统计
        textView.delegate = self
        
        scrollView.documentView = textView
        
        // 添加子视图
        addSubview(scrollView)
    }
    
    override func layout() {
        super.layout()
        scrollView.frame = bounds
    }
    
    private func updateWordCount() {
        let text = textView?.string ?? ""
        wordCount = text.count
    }
}

extension SwiftUITextViewWrapper: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        updateWordCount()
    }
}

// MARK: - Status Bar

struct StatusBarView: View {
    let wordCount: Int
    
    var body: some View {
        HStack {
            Text("字符数：\(wordCount)")
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

// MARK: - Helper Extensions

extension NSView {
    func firstSubview(where predicate: (NSView) -> Bool) -> NSView? {
        if predicate(self) { return self }
        for subview in subviews {
            if let found = subview.firstSubview(where: predicate) {
                return found
            }
        }
        return nil
    }
}
