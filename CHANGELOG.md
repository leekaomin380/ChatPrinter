# ChatPrinter 版本更新日志

所有重要的项目变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

---

## [2.0.0] - 2026-02-20

### 修复
- **编译失败** — 删除 `Notification.Name` 在两个文件中的重复定义（v1.9.0 以来项目无法编译的根本原因）
- **重复文件** — 删除根目录多余的 `MarkdownRenderer.swift`，保留 Managers 版本
- **渲染闪退** — 修复 `applyInlineFormats` 中处理粗体后字符串变短导致斜体/代码正则越界崩溃
- **斜体 API 错误** — `NSFontDescriptor.TraitKey.style` 不存在，改用 `withSymbolicTraits(.italic)`
- **打印按钮无效** — 改用 Combine 订阅替代 `updateNSView` 转发，确保所有操作可靠触发
- **关于页面无法关闭** — 添加关闭按钮和 `@Environment(\.dismiss)`
- **关于页面图标显示不全** — 改用 `NSApp.applicationIconImage` 显示应用真实图标
- **线程安全** — `handleRenderMarkdown` 改为主线程取值、后台渲染，避免在后台线程访问 NSTextView
- **富文本被覆盖** — `updateNSView` 不再在渲染后强制重设字体

### 架构改善
- **通信机制重构** — 视图内通信从 NotificationCenter 改为 ObservableObject + Combine，消除 Coordinator 生命周期隐患
- **Coordinator 过期引用** — fontSize/fontFamily 作为 Coordinator 属性，在 `updateNSView` 中同步
- App 菜单栏通知保留 NotificationCenter（跨组件通信场景合理）
- Coordinator 添加 `deinit` 清理 observer，防止内存泄漏

### 版本号
- Info.plist 版本号从 1.9.0 更新为 2.0.0

---

## [1.9.0] - 2026-02-20

### 新增
- ✅ **双业务线架构** - 屏幕阅读助手 + 电子书助手（预览版）
- ✅ **侧边栏导航** - 固定宽度 200pt，切换两种模式
- ✅ **电子书助手界面** - EPUB 导入功能
- ✅ **关于页面** - 显示版本号、致谢信息
  - 感谢富士通 reMarkable 电子纸设备
- ✅ **PDF 导出框架** - PDFExportManager

### 部分实现
- ⚠️ **EPUB 解析** - EPUBParser 可解析元数据和章节，但无 UI 预览
- ⚠️ **PDF 导出** - 创建空 PDF 作为占位，待完整实现

### 屏幕阅读助手 - 完整功能
- ✅ 粘贴聊天记录
- ✅ Markdown 渲染（标题、粗体、斜体、列表、代码）
- ✅ 字体选择（5 种字体，包括宋体）
- ✅ 字体大小调节 (8-72pt)
- ✅ 文本滚动和编辑
- ✅ 打印到电子纸

### 已知问题
- ⚠️ **电子书助手** - 仅框架，核心功能待实现
  - EPUB 预览界面未实现
  - 章节导航未实现
  - PDF 导出为占位实现

### 技术实现
- 使用原生 ZIP/XML 解析 EPUB（无需外部依赖）
- 创建 PDFExportManager 管理 PDF 导出
- 创建 EPUBParser 解析 EPUB 文件
- 使用 CGContext 创建 PDF
- 通知中心实现跨视图通信

### 后续任务 (v2.0.0)
- [ ] 实现 EPUB 预览界面（渲染 EPUB 内容到 NSTextView）
- [ ] 实现章节导航（显示目录并支持跳转）
- [ ] 完整 PDF 导出（将 EPUB 内容正确转换为 PDF）
- [ ] CSS 样式解析和应用
- [ ] 阅读进度保存

---

## [1.1.2] - 2026-02-20

### 新增
- ✅ **无序列表支持** - 渲染 `*`, `-`, `+` 开头的列表项为圆点 `•`
- ✅ **Markdown 符号自动移除** - 渲染后只保留格式，符号消失
  - 标题 `#` 符号移除
  - 粗体 `**` 符号移除
  - 斜体 `*` 符号移除
  - 行内代码 `` ` `` 符号移除

### 修复
- ✅ **右边缘文字显示不完整** - 增加 `lineFragmentPadding = 10`
- ✅ **渲染逻辑优化** - 先处理无序列表再处理斜体，避免冲突

### 技术实现
- `renderMarkdown` 返回元组 `(attributedString, processedString)`
- 使用 `replaceCharacters` 移除 Markdown 符号
- 正则表达式匹配无序列表

---

## [1.1.1] - 2026-02-20

### 新增
- ✅ 中文本地化支持 (zh-Hans.lproj)
- ✅ 字体菜单新增宋体 (STSong) 选项，优化汉字显示
- ✅ Info.plist 默认语言设置为中文

### 修复
- ✅ Markdown 渲染闪退问题 - 添加错误处理和提示对话框
- ✅ 渲染逻辑优化 - 只添加样式属性，不删除 Markdown 标记

---

## [1.1.0] - 2026-02-20

### 新增
- ✅ Markdown 渲染功能 - 新增"渲染 MD"按钮
  - 标题渲染 (`#`, `##`, `###`)
  - 粗体渲染 (`**text**`)
  - 斜体渲染 (`*text*`)
  - 行内代码渲染 (`` `code` ``)
- ✅ 字体选择菜单 - 5 种字体可选

### 修复
- ✅ 文本区域无法滚动的问题
- ✅ 文本区域现在完全可编辑

### 技术实现
- 使用 `NSAttributedString` 渲染富文本
- 正则表达式解析 Markdown 语法
- `NSFontDescriptor` 实现字体切换
- 优化 `NSScrollView` 约束和自动调整大小

---

## [1.0.0] - 2026-02-20

### 新增
- ✅ NSTextView 可编辑文本区域
- ✅ 格式保留（支持 Markdown/富文本）
- ✅ 系统打印集成（NSPrintOperation）
- ✅ 字体大小调节 (8-72pt)
- ✅ 字数统计
- ✅ 快捷键支持 (⌘V, ⌘P, ⌘N, ⌘+/-)

### 优化
- ✅ 36pt 标准打印边距
- ✅ 1.5 倍行距
- ✅ 纯白背景，黑色文字
- ✅ 无限制打印量

---

## [0.1.1] - 2026-02-20

### 修复
- ✅ 编译错误 - 使用 NSViewRepresentable 包装 NSTextView
- ✅ 打印权限 - 添加 com.apple.security.print 权限

### 改进
- ✅ 使用 Binding 管理文本状态
- ✅ 通过 NotificationCenter 实现组件间通信
- ✅ 字数统计实时更新

---

## [0.1.0] - 2026-02-20

### 新增
- ✅ 项目结构和技术文档
- ✅ README.md 使用说明
- ✅ TECHNICAL.md 技术文档（含版本记录）
- ✅ .gitignore 配置

### 规划功能
- 粘贴聊天记录
- 调用系统打印到电子纸
- 纯白背景，打印优化

---

## 版本说明

- **主版本号 (Major)**: 不兼容的 API 变更
- **次版本号 (Minor)**: 向下兼容的功能性新增
- **修订号 (Patch)**: 向下兼容的问题修正

**1.9.0** 是预览版本，为 v2.0.0 做准备。

**项目仓库**: https://github.com/leekaomin380/ChatPrinter
