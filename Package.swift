// swift-tools-version:5.9
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
        .package(url: "https://github.com/iwasrobbed/Down.git", from: "0.11.0")
    ],
    targets: [
        .executableTarget(
            name: "ChatPrinter",
            dependencies: ["Down"],
            path: "ChatPrinter"
        )
    ]
)
