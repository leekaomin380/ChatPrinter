# ChatPrinter 技术文档

## 版本记录

| 版本 | 日期 | 作者 | 变更说明 |
|------|------|------|----------|
| 0.1.0 | 2026-02-20 | - | 初始版本，核心功能实现 |
| 0.1.1 | 2026-02-20 | - | 完整 Swift 实现：可编辑、格式保留、无限制打印 |
| 1.1.0 | 2026-02-20 | - | 功能增强版本：滚动修复、MD 渲染、字体选择、可编辑 |

## 1.1.0 版本新功能

### 问题修复
- ✅ **滚动问题**: 修复文本区域无法滚动的问题，现在可以正常滚动查看所有内容
- ✅ **可编辑**: 文本区域现在完全可编辑，可以直接修改内容

### 新增功能
- ✅ **Markdown 渲染**: 新增"渲染 MD"按钮，支持渲染以下格式：
  - 标题 (`#`, `##`, `###`)
  - 粗体 (`**text**`)
  - 斜体 (`*text*`)
  - 行内代码 (`` `code` ``)
- ✅ **字体选择**: 工具栏新增字体选择菜单，支持：
  - Helvetica (默认)
  - Times New Roman
  - Georgia
  - Courier New
  - Arial

### 技术实现
- 使用 `NSFontDescriptor` 实现字体切换
- 使用正则表达式解析 Markdown 语法
- 使用 `NSAttributedString` 渲染富文本
- 优化 `NSScrollView` 约束设置以支持滚动 |

## 架构设计

### 技术栈

- **语言**: Swift 5.9+
- **框架**: AppKit (macOS 原生)
- **部署目标**: macOS 12.0+

### 项目结构

```
ChatPrinter/
├── ChatPrinter.xcodeproj       # Xcode 项目
├── ChatPrinter/
│   ├── ChatPrinterApp.swift    # 应用入口
│   ├── ContentView.swift       # 主界面视图
│   ├── PrintManager.swift      # 打印功能管理
│   ├── Assets.xcassets         # 资源文件
│   ├── Info.plist             # 应用配置
│   └── ChatPrinter.entitlements # 沙盒权限
├── README.md
├── TECHNICAL.md
└── .gitignore
```

## 核心模块

### 1. 主界面 (ContentView)

**功能组件**:
- NSTextView: 可编辑、可格式化文本区域
- 工具栏：粘贴、打印、清除、字体调节
- 状态栏：字数统计

**设计原则**:
- 极简主义，无干扰
- 打印预览即所得
- 纯白背景，黑色文字
- 支持 Markdown 格式保留

### 2. 打印管理 (PrintManager)

```swift
// 核心 API
- NSPrintOperation: 系统打印对话框
- NSPrintInfo: 打印配置（边距、纸张、缩放）
```

**打印配置**:
| 参数 | 值 | 说明 |
|------|-----|------|
| 边距 | 20pt | 标准打印边距 |
| 字体 | Helvetica | 清晰易读 |
| 默认字号 | 12pt | 平衡密度与可读性 |
| 行距 | 1.5 | 舒适阅读 |

### 3. 数据流

```
用户操作 → NSTextView → PrintManager → NSPrintOperation → 系统打印队列
```

## 关键实现

### 打印功能

```swift
let printInfo = NSPrintInfo.shared
printInfo.isHorizontallyCentered = false
printInfo.isVerticallyCentered = false
printInfo.topMargin = 20
printInfo.leftMargin = 20
printInfo.rightMargin = 20
printInfo.bottomMargin = 20

let operation = NSPrintOperation(view: textView, printInfo: printInfo)
operation.run()
```

### 快捷键支持

```swift
// 在 ContentView 中实现
.onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
    // 注册快捷键
}
```

## 未来改进方向

### 功能增强

- [ ] 自动分页优化
- [ ] 导出 PDF 功能
- [ ] 多文档标签页
- [ ] 历史记录保存
- [ ] 批量导入（支持直接粘贴多个对话）

### 打印优化

- [ ] 自定义页眉页脚
- [ ] 二维码/时间戳水印
- [ ] 智能分页（避免对话在中间断开）
- [ ] 打印预览功能

### 用户体验

- [ ] 自动保存草稿
- [ ] 字数统计
- [ ] 暗黑模式（仅界面，打印仍为白底黑字）
- [ ] 拖拽文件导入

## 已知限制

1. 仅支持 macOS 平台
2. 需要系统打印对话框支持电子纸驱动

## 构建说明

### 开发环境

```bash
# 检查 Xcode 版本
xcodebuild -version

# 检查 Swift 版本
swift --version
```

### 构建命令

```bash
# Debug 构建
xcodebuild -scheme ChatPrinter -configuration Debug build

# Release 构建
xcodebuild -scheme ChatPrinter -configuration Release build

# 生成 App
xcodebuild -scheme ChatPrinter -configuration Release archive \
  -archivePath ./build/ChatPrinter.xcarchive
```

## 参考资源

- [NSPrintOperation Documentation](https://developer.apple.com/documentation/appkit/nsprintoperation)
- [NSTextView Documentation](https://developer.apple.com/documentation/appkit/nstextview)
- [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos/overview/themes/)
