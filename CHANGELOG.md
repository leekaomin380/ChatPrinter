# ChatPrinter 版本更新日志

所有重要的项目变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

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
- ✅ 字体选择菜单 - 支持 5 种字体切换
  - Helvetica (默认)
  - Times New Roman
  - Georgia
  - Courier New
  - Arial

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

## 未来计划

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
- [ ] 暗黑模式（仅界面，打印仍为白底黑字）
- [ ] 拖拽文件导入

---

## 版本说明

- **主版本号 (Major)**: 不兼容的 API 变更
- **次版本号 (Minor)**: 向下兼容的功能性新增
- **修订号 (Patch)**: 向下兼容的问题修正

**项目仓库**: https://github.com/leekaomin380/ChatPrinter
