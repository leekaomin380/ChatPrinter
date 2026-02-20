//
//  ChatPrinterApp.swift
//  ChatPrinter
//
//  将 AI 聊天记录打印到电子纸
//

import SwiftUI

@main
struct ChatPrinterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, minHeight: 500)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New") {
                    NotificationCenter.default.post(name: .newDocument, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Divider()
                
                Button("Print") {
                    NotificationCenter.default.post(name: .printDocument, object: nil)
                }
                .keyboardShortcut("p", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let newDocument = Notification.Name("newDocument")
    static let printDocument = Notification.Name("printDocument")
}
