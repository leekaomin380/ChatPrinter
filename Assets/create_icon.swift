import AppKit

let sizes = [16, 32, 64, 128, 256, 512]
let outputDir = "/Users/gm/projects/ChatPrinter/Assets"

for size in sizes {
    // 创建图像
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    
    // 白色背景
    NSColor.white.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()
    
    // 黑色衬线字体 P
    let fontSize = Double(size) * 0.7
    let font = NSFont(name: "Times New Roman", size: fontSize) ?? NSFont(name: "Georgia", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize, weight: .bold)
    let text = "P" as NSString
    
    // 居中绘制
    let textRect = NSRect(x: 0, y: (size - Int(fontSize)) / 2, width: size, height: Int(fontSize))
    text.draw(in: textRect, withAttributes: [
        .font: font,
        .foregroundColor: NSColor.black
    ])
    
    image.unlockFocus()
    
    // 保存为 PNG
    if let tiffData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        let url = URL(fileURLWithPath: "\(outputDir)/icon_\(size)x\(size).png")
        try? pngData.write(to: url)
        print("Created: icon_\(size)x\(size).png (\(size)x\(size))")
    }
}

print("Done!")
