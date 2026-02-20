# ChatPrinter

将 AI 聊天记录打印到富士通电子纸的 macOS 应用。

## 使用场景

1. 从 AI 客户端复制聊天记录
2. 粘贴到 ChatPrinter
3. 调用系统打印，选择富士通电子纸
4. 在电子纸上舒适阅读

## 系统要求

- macOS 12.0+
- Xcode 14+

## 快速开始

```bash
# 打开 Xcode 项目
open ChatPrinter.xcodeproj

# 或命令行构建
xcodebuild -scheme ChatPrinter -configuration Release build
```

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| ⌘V | 粘贴 |
| ⌘P | 打印 |
| ⌘N | 新建 |
| ⌘+ | 增大字体 |
| ⌘- | 减小字体 |

## 打印优化

- 纯白背景，黑色文字
- 无多余装饰，最大化内容密度
- 适合电子纸显示
