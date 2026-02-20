// swift-tools-version:5.9
// 注意：当前版本暂不依赖外部 EPUB 库
// EPUB 解析使用原生 ZIP + XML 解析方式

import PackageDescription

let package = Package(
    name: "ChatPrinter",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "ChatPrinter",
            targets: ["ChatPrinter"]
        )
    ],
    dependencies: [
        // 暂无外部依赖
        // 未来可能添加：
        // - EPUB 解析库
        // - PDF 增强库
    ],
    targets: [
        .executableTarget(
            name: "ChatPrinter",
            dependencies: [],
            path: "ChatPrinter"
        )
    ]
)
