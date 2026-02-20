//
//  ContentView.swift
//  ChatPrinter
//
//  主容器视图
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var selectedMode: AppMode = .screenReader
    @State private var showAbout = false
    
    var body: some View {
        HStack(spacing: 0) {
            // 侧边栏
            SidebarView(selectedMode: $selectedMode, showAbout: $showAbout)
            
            Divider()
            
            // 主内容区域
            Group {
                switch selectedMode {
                case .screenReader:
                    ScreenReaderView()
                case .ebookReader:
                    EbookReaderView()
                }
            }
            .frame(minWidth: 600, minHeight: 500)
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
