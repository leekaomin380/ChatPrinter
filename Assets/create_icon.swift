import AppKit

let outputDir = "/Users/gm/projects/ChatPrinter/Assets"
let iconsetDir = "\(outputDir)/Icon.iconset"

// 创建 iconset 目录
try? FileManager.default.removeItem(atPath: iconsetDir)
try! FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_32x32.png"),
    (64, "icon_64x64.png"),
    (128, "icon_128x128.png"),
    (256, "icon_256x256.png"),
    (512, "icon_512x512.png")
]

for (size, filename) in sizes {
    // 创建图像
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    
    // 纯白色背景（不透明）
    NSColor.white.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()
    
    // 黑色衬线字体 P
    let fontSize = Double(size) * 0.65
    let font = NSFont(name: "Times New Roman", size: fontSize) ?? NSFont(name: "Georgia", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize, weight: .bold)
    let text = "P" as NSString
    
    // 计算居中位置
    let textBounds = text.boundingRect(with: NSSize(width: size, height: size), options: [], attributes: [.font: font])
    let x = (Double(size) - textBounds.width) / 2.0
    let y = (Double(size) - textBounds.height) / 2.0
    
    text.draw(at: NSPoint(x: x, y: y), withAttributes: [
        .font: font,
        .foregroundColor: NSColor.black
    ])
    
    image.unlockFocus()
    
    // 保存为 PNG
    if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        let pngData = bitmapRep.representation(using: .png, properties: [.compressionFactor: 0.9])
        try? pngData?.write(to: URL(fileURLWithPath: "\(iconsetDir)/\(filename)"))
        print("Created: \(filename)")
    }
}

// 转换为 icns
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", "-o", "\(outputDir)/Icon.icns", iconsetDir]
try! iconutil.run()

print("Created: Icon.icns")
print("Done!")
