# File Standby

一个原生 macOS 临时文件架。把 Finder 中的文件或文件夹先放到屏幕边缘，需要时再拖到目标窗口，减少在多个目录之间来回切换。

> 当前版本保存的是原文件引用：拖入不会复制、移动或删除原文件。原文件被删除、外置盘离线或云文件不可访问时，项目会保留在文件架并显示“原文件不可用”。

## 已实现

- 菜单栏常驻，不占用 Dock
- 自定义 macOS 应用图标，主界面和菜单栏视觉一致
- 主屏幕右侧常驻投放拉手，点击或拖入文件时展开
- 支持从 Finder 拖入多个文件和文件夹
- 拖动整张文件卡片到 Finder 或其他支持文件 URL 的应用
- 拖动顶部标题区域可自由调整文件架位置
- 蓝色文件接收器只能沿屏幕四周移动，不能停在屏幕中间；顶部/底部为横向，左侧/右侧为竖向
- 接收器始终保持 112 × 26 的统一长短边规格，只随所在边缘旋转方向
- 移动接收器后文件架会在松手时就近跟随，收起箭头始终指向接收器；接收器未移动时保留文件架位置
- 重启后恢复接收器的位置和方向
- 双击或点击眼睛按钮使用 Quick Look 预览
- 在 Finder 中显示、复制路径、单项移除和全部清空
- 主界面和菜单栏均可退出 File Standby
- 使用 bookmark + JSON 持久化，重启后恢复文件架
- 原文件不可用时显示明确状态，不崩溃、不自动清理

## 运行

要求 macOS 14 或更高版本，以及 Xcode 16 或更高版本。

直接从源码运行：

```bash
swift run FileStandby
```

生成可双击启动的应用：

```bash
./scripts/build-app.sh
open .build/FileStandby.app
```

脚本会生成临时 ad-hoc 签名的 `.build/FileStandby.app`。正式分发时应改用 Apple Developer 证书完成签名、公证，并根据发布渠道启用 App Sandbox。

## 使用方式

1. 从 Finder 把文件或文件夹拖到右侧拉手，或展开后的文件架。
2. 在文件架里双击卡片进行 Quick Look；右键可在 Finder 中定位或复制路径。
3. 拖动整张文件卡片到目标 Finder 窗口或其他应用。
4. 按住顶部标题区域拖动，可调整文件架在屏幕上的位置。
5. 完成后手动移除卡片；移除卡片不会删除原文件。

## 开发

```bash
swift build
swift test
```

主要结构：

```text
Sources/FileStandby/
├── Models/       # 暂存项目模型
├── Services/     # 持久化、状态管理、Quick Look
├── Views/        # SwiftUI 文件架与卡片
└── Window/       # AppKit 浮动面板、边缘拉手与拖放
```

## 许可证

File Standby 使用 MIT License 开源，版权归 xuxinyuan 所有。详见 [LICENSE](LICENSE)。

## 后续路线

- App Sandbox 与 security-scoped bookmark 的正式分发配置
- Quick Look 缩略图异步缓存
- 登录时启动
- 多显示器与左右边缘选择
- 文本、网址、图片数据和 promised files
- 多文件架、分组与自动清理策略
