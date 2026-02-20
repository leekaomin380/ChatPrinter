//
//  AboutView.swift
//  ChatPrinter
//
//  关于页面
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            // 应用图标
            Image(systemName: "printer.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
            
            // 应用名称
            Text("ChatPrinter")
                .font(.title)
                .fontWeight(.bold)
            
            // 版本号
            HStack {
                Text("版本")
                Text(versionNumber)
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Divider()
            
            // 应用描述
            Text("将 AI 聊天记录和电子书打印到电子纸的 macOS 应用")
                .font(.body)
                .multilineTextAlignment(.center)
            
            // 致谢
            VStack(alignment: .leading, spacing: 12) {
                Text("致谢")
                    .font(.headline)
                
                // EPUB 库致谢
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                    Text("感谢 FolioReaderKit 提供的 EPUB 解析功能 (MIT License)")
                }
                .font(.caption)
                
                // 硬件致谢
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("感谢富士通公司提供的 reMarkable 电子纸设备")
                        Text("这是一个可靠的工具，让阅读更加舒适")
                    }
                    .font(.caption)
                }
            }
            
            Spacer()
            
            // 版权信息
            Text("© 2026 ChatPrinter. All rights reserved.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(width: 400, height: 350)
    }
    
    private var versionNumber: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
