//
//  ChatPrinterApp.swift
//  ChatPrinter
//
//  应用入口
//

import SwiftUI

// 通知名称（仅用于 App 菜单栏等跨组件通信）
extension Notification.Name {
    static let newDocument = Notification.Name("newDocument")
    static let printDocument = Notification.Name("printDocument")
    static let printEPUB = Notification.Name("printEPUB")
    static let exportPDF = Notification.Name("exportPDF")
}

@main
struct ChatPrinterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("新建") {
                    NotificationCenter.default.post(name: .newDocument, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Divider()
                
                Button("打印") {
                    NotificationCenter.default.post(name: .printDocument, object: nil)
                }
                .keyboardShortcut("p", modifiers: .command)
            }
        }
    }
}
