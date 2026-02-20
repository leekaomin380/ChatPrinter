//
//  SidebarView.swift
//  ChatPrinter
//
//  侧边栏导航
//

import SwiftUI

enum AppMode: String, CaseIterable {
    case screenReader = "screenReader"
    case ebookReader = "ebookReader"
    
    var title: String {
        switch self {
        case .screenReader:
            return "屏幕阅读助手"
        case .ebookReader:
            return "电子书助手"
        }
    }
    
    var icon: String {
        switch self {
        case .screenReader:
            return "doc.text"
        case .ebookReader:
            return "book.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .screenReader:
            return .blue
        case .ebookReader:
            return .purple
        }
    }
}

struct SidebarView: View {
    @Binding var selectedMode: AppMode
    @Binding var showAbout: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 应用标题
            Text("ChatPrinter")
                .font(.headline)
                .padding(.vertical, 12)
            
            Divider()
            
            // 模式选择
            VStack(spacing: 4) {
                ForEach(AppMode.allCases, id: \.self) { mode in
                    ModeButton(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        action: {
                            selectedMode = mode
                        }
                    )
                }
            }
            .padding(.horizontal, 8)
            
            Spacer()
            
            Divider()
            
            // 关于按钮
            Button(action: { showAbout = true }) {
                HStack {
                    Image(systemName: "info.circle")
                        .frame(width: 20)
                    Text("关于")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.clear)
                .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 200)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ModeButton: View {
    let mode: AppMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: mode.icon)
                    .frame(width: 20)
                    .foregroundColor(isSelected ? .white : mode.color)
                
                Text(mode.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(isSelected ? .white : .primary)
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? mode.color : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        @State var selectedMode = AppMode.screenReader
        @State var showAbout = false
        
        return SidebarView(selectedMode: $selectedMode, showAbout: $showAbout)
    }
}
