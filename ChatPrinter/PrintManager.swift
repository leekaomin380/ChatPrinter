//
//  PrintManager.swift
//  ChatPrinter
//
//  打印管理器 - 优化电子纸打印输出
//

import AppKit

class PrintManager {
    static let shared = PrintManager()
    
    private init() {}
    
    /// 打印文本视图内容
    func printTextView(_ textView: NSTextView) {
        guard !textView.string.isEmpty else {
            showAlert(message: "没有可打印的内容", informativeText: "请先粘贴聊天记录")
            return
        }
        
        // 配置打印信息
        let printInfo = NSPrintInfo.shared
        setupPrintInfo(printInfo)
        
        // 创建打印操作
        let printView = createPrintView(from: textView)
        let operation = NSPrintOperation(view: printView, printInfo: printInfo)
        operation.showsPrintPanel = true
        operation.showsProgressPanel = true
        
        // 执行打印
        operation.run()
    }
    
    /// 配置打印参数 - 针对电子纸优化
    private func setupPrintInfo(_ printInfo: NSPrintInfo) {
        // 边距设置（点）
        printInfo.topMargin = 36      // 0.5 英寸
        printInfo.leftMargin = 36     // 0.5 英寸
        printInfo.rightMargin = 36    // 0.5 英寸
        printInfo.bottomMargin = 36   // 0.5 英寸
        
        // 不居中，从左上角开始
        printInfo.isHorizontallyCentered = false
        printInfo.isVerticallyCentered = false
        
        // 缩放比例
        printInfo.scaleFactor = 1.0
        
        // 打印方向（自动）
        printInfo.orientation = .portrait
    }
    
    /// 创建打印视图 - 保留格式，纯白背景
    private func createPrintView(from textView: NSTextView) -> NSView {
        let container = NSView()
        
        // 创建用于打印的文本视图
        let textStorage = NSTextStorage(attributedString: textView.attributedString())
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer()
        
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        
        // 设置容器宽度为 A4 纸宽度减去边距（约 540 点）
        textContainer.containerSize = NSSize(width: 540, height: CGFloat.greatestFiniteMagnitude)
        textContainer.widthTracksTextView = true
        
        let printTextView = NSTextView(frame: .zero, textContainer: textContainer)
        printTextView.textStorage?.setAttributedString(textView.attributedString())
        printTextView.font = textView.font ?? NSFont.systemFont(ofSize: 12)
        printTextView.textColor = NSColor.black
        printTextView.drawsBackground = false  // 打印时不绘制背景
        
        // 段落样式
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.5
        printTextView.defaultParagraphStyle = paragraphStyle
        
        // 自动调整大小
        printTextView.autoresizingMask = [.width]
        
        // 计算所需高度
        layoutManager.glyphRange(forTextContainer: textContainer)
        let textHeight = layoutManager.usedRect(forTextContainer: textContainer).height
        
        container.frame = NSRect(x: 0, y: 0, width: 540, height: max(textHeight, 100))
        printTextView.frame = container.bounds
        
        container.addSubview(printTextView)
        
        return container
    }
    
    /// 显示提示对话框
    private func showAlert(message: String, informativeText: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informativeText
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
}
