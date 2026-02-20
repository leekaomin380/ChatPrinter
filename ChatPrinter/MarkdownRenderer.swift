//
//  MarkdownRenderer.swift
//  ChatPrinter
//
//  完整的 Markdown 渲染器
//

import AppKit

class MarkdownRenderer {
    
    /// 渲染 Markdown 为 NSAttributedString
    static func render(_ markdown: String, fontFamily: String, fontSize: CGFloat) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: .newlines)
        
        var skipNext = false
        
        for (index, line) in lines.enumerated() {
            if skipNext {
                skipNext = false
                continue
            }
            
            // 检查代码块
            if line.hasPrefix("```") {
                let codeLines = collectCodeBlock(from: lines, startingAt: index + 1)
                let codeString = codeLines.joined(separator: "\n")
                let codeAttr = renderCodeBlock(codeString, fontFamily: fontFamily, fontSize: fontSize)
                attributedString.append(codeAttr)
                skipNext = true
                continue
            }
            
            // 分割线
            if isHorizontalRule(line) {
                attributedString.append(renderHorizontalRule())
                continue
            }
            
            // 标题
            if let (level, text) = parseHeader(line) {
                attributedString.append(renderHeader(text, level: level, fontFamily: fontFamily, fontSize: fontSize))
                continue
            }
            
            // 引用块
            if let text = parseBlockquote(line) {
                attributedString.append(renderBlockquote(text, fontFamily: fontFamily, fontSize: fontSize))
                continue
            }
            
            // 有序列表
            if let (number, text) = parseOrderedList(line) {
                attributedString.append(renderOrderedList(text, number: number, fontFamily: fontFamily, fontSize: fontSize))
                continue
            }
            
            // 无序列表
            if let text = parseUnorderedList(line) {
                attributedString.append(renderUnorderedList(text, fontFamily: fontFamily, fontSize: fontSize))
                continue
            }
            
            // 普通段落
            if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                attributedString.append(renderParagraph(line, fontFamily: fontFamily, fontSize: fontSize))
            } else {
                // 空行
                attributedString.append(NSAttributedString(string: "\n"))
            }
        }
        
        return attributedString
    }
    
    // MARK: - 解析函数
    
    private static func parseHeader(_ line: String) -> (level: Int, text: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        for level in (1...6).reversed() {
            let prefix = String(repeating: "#", count: level)
            if trimmed.hasPrefix(prefix + " ") {
                return (level, String(trimmed.dropFirst(level + 1)))
            }
        }
        return nil
    }
    
    private static func parseBlockquote(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("> ") {
            return String(trimmed.dropFirst(2))
        } else if trimmed.hasPrefix(">") {
            return String(trimmed.dropFirst(1)).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
    
    private static func parseOrderedList(_ line: String) -> (number: Int, text: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let pattern = #"^(\d+)\.\s+(.+)$"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           let numberRange = Range(match.range(at: 1), in: trimmed),
           let textRange = Range(match.range(at: 2), in: trimmed) {
            let number = Int(trimmed[numberRange]) ?? 0
            let text = String(trimmed[textRange])
            return (number, text)
        }
        return nil
    }
    
    private static func parseUnorderedList(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
            return String(trimmed.dropFirst(2))
        }
        return nil
    }
    
    private static func isHorizontalRule(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.count < 3 { return false }
        let chars = Set(trimmed)
        return (chars == ["-"] || chars == ["*"] || chars == ["_"]) && trimmed.count >= 3
    }
    
    // MARK: - 渲染函数
    
    private static func renderHeader(_ text: String, level: Int, fontFamily: String, fontSize: CGFloat) -> NSAttributedString {
        let sizeMultipliers: [Double] = [0, 2.0, 1.8, 1.6, 1.4, 1.2, 1.0]
        let size = fontSize * (level < sizeMultipliers.count ? sizeMultipliers[level] : 1.0)
        let font = NSFont(name: fontFamily, size: size) ?? NSFont.boldSystemFont(ofSize: size)
        
        let attributedString = NSMutableAttributedString(string: text + "\n")
        attributedString.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(.foregroundColor, value: NSColor.black, range: NSRange(location: 0, length: attributedString.length))
        
        // 处理行内格式
        applyInlineFormats(attributedString, fontFamily: fontFamily, baseFontSize: size)
        
        return attributedString
    }
    
    private static func renderBlockquote(_ text: String, fontFamily: String, fontSize: CGFloat) -> NSAttributedString {
        let font = NSFont(name: fontFamily, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        let attributedString = NSMutableAttributedString(string: "  " + text + "\n")
        attributedString.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(.foregroundColor, value: NSColor.darkGray, range: NSRange(location: 0, length: attributedString.length))
        return attributedString
    }
    
    private static func renderOrderedList(_ text: String, number: Int, fontFamily: String, fontSize: CGFloat) -> NSAttributedString {
        let font = NSFont(name: fontFamily, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        let attributedString = NSMutableAttributedString(string: "  \(number). " + text + "\n")
        attributedString.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(.foregroundColor, value: NSColor.black, range: NSRange(location: 0, length: attributedString.length))
        applyInlineFormats(attributedString, fontFamily: fontFamily, baseFontSize: fontSize)
        return attributedString
    }
    
    private static func renderUnorderedList(_ text: String, fontFamily: String, fontSize: CGFloat) -> NSAttributedString {
        let font = NSFont(name: fontFamily, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        let attributedString = NSMutableAttributedString(string: "  • " + text + "\n")
        attributedString.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(.foregroundColor, value: NSColor.black, range: NSRange(location: 0, length: attributedString.length))
        applyInlineFormats(attributedString, fontFamily: fontFamily, baseFontSize: fontSize)
        return attributedString
    }
    
    private static func renderParagraph(_ text: String, fontFamily: String, fontSize: CGFloat) -> NSAttributedString {
        let font = NSFont(name: fontFamily, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        let attributedString = NSMutableAttributedString(string: text + "\n")
        attributedString.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(.foregroundColor, value: NSColor.black, range: NSRange(location: 0, length: attributedString.length))
        applyInlineFormats(attributedString, fontFamily: fontFamily, baseFontSize: fontSize)
        return attributedString
    }
    
    private static func renderHorizontalRule() -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: "\n───────────────────────────────────────\n\n")
        attributedString.addAttribute(.foregroundColor, value: NSColor.lightGray, range: NSRange(location: 0, length: attributedString.length))
        return attributedString
    }
    
    private static func renderCodeBlock(_ code: String, fontFamily: String, fontSize: CGFloat) -> NSAttributedString {
        let codeFont = NSFont(name: "Menlo", size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let attributedString = NSMutableAttributedString(string: "\n" + code + "\n\n")
        attributedString.addAttribute(.font, value: codeFont, range: NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(.foregroundColor, value: NSColor.black, range: NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(.backgroundColor, value: NSColor.lightGray.withAlphaComponent(0.2), range: NSRange(location: 0, length: attributedString.length))
        return attributedString
    }
    
    // MARK: - 行内格式
    
    private static func applyInlineFormats(_ attributedString: NSMutableAttributedString, fontFamily: String, baseFontSize: CGFloat) {
        // 每次替换后必须重新获取 string，因为 replaceCharacters 会改变长度
        applyInlineFormat(attributedString, pattern: "\\*\\*(.+?)\\*\\*") { nsRange in
            let boldFont = NSFont(name: fontFamily, size: baseFontSize) ?? NSFont.boldSystemFont(ofSize: baseFontSize)
            attributedString.addAttribute(.font, value: boldFont, range: nsRange)
        }

        applyInlineFormat(attributedString, pattern: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)") { nsRange in
            let baseFont = NSFont(name: fontFamily, size: baseFontSize) ?? NSFont.systemFont(ofSize: baseFontSize)
            let italicDescriptor = baseFont.fontDescriptor.withSymbolicTraits(.italic)
            let italicFont = NSFont(descriptor: italicDescriptor, size: baseFontSize) ?? baseFont
            attributedString.addAttribute(.font, value: italicFont, range: nsRange)
        }

        applyInlineFormat(attributedString, pattern: "`([^`]+)`") { nsRange in
            let codeFont = NSFont(name: "Menlo", size: baseFontSize) ?? NSFont.monospacedSystemFont(ofSize: baseFontSize, weight: .regular)
            attributedString.addAttribute(.font, value: codeFont, range: nsRange)
            attributedString.addAttribute(.backgroundColor, value: NSColor.lightGray.withAlphaComponent(0.2), range: nsRange)
        }
    }

    private static func applyInlineFormat(_ attributedString: NSMutableAttributedString, pattern: String, applyAttributes: (NSRange) -> Void) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }

        // 每次循环重新获取当前 string，从后往前替换避免偏移
        while true {
            let currentText = attributedString.string
            let searchRange = NSRange(currentText.startIndex..., in: currentText)
            guard let match = regex.firstMatch(in: currentText, range: searchRange) else { break }

            let fullNSRange = match.range
            let contentNSRange = match.range(at: 1)
            guard let contentRange = Range(contentNSRange, in: currentText) else { break }

            let contentString = String(currentText[contentRange])

            // 先应用样式到内容范围
            applyAttributes(contentNSRange)
            // 再替换（去除标记符号），用当前 string 的范围
            attributedString.replaceCharacters(in: fullNSRange, with: contentString)
        }
    }
    
    // MARK: - 辅助函数
    
    private static func collectCodeBlock(from lines: [String], startingAt index: Int) -> [String] {
        var codeLines: [String] = []
        for i in index..<lines.count {
            if lines[i].hasPrefix("```") {
                return codeLines
            }
            codeLines.append(lines[i])
        }
        return codeLines
    }
}
