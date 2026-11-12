---
title: DigUp 本地语义文件搜索
category: 生产力
tags: [digup, search, documents, wayland]
updated: 2026-11-12
---

# DigUp 本地语义文件搜索

DigUp 按内容含义和关键词搜索自己选定的文件夹，支持文档、图片、PDF、录音、视频和可选的代码搜索。
本仓库固定 Linux 测试版 **0.7.0-beta.3**，通过 Home Manager 的文件工具模块安装到两个桌面变体。

## 打开与首次设置

应用菜单中选择 **DigUp**，或执行：

```bash
digup-shell
```

1. 首次打开会下载约 865 MB 的模型，文件索引另占空间。
2. 在设置中选择需要搜索的文件夹，建议先用一个小目录确认效果。
3. 等待初次索引完成，再输入自然语言描述或文件中的关键词。
4. 在托盘菜单或窗口菜单中查看进度、暂停索引、打开设置或退出。

包本身不携带模型、不预设搜索目录，也不声明登录自启。
模型和索引保存在可写用户目录，系统回滚不会自动删除它们。

## 常用操作

| 操作 | 按键或入口 |
| --- | --- |
| 选择搜索结果 | 上、下方向键 |
| 打开结果 | Enter |
| 预览选中结果 | Space |
| 在文件管理器显示 | Ctrl + Enter |
| 打开较大的搜索窗口 | Ctrl + O |
| 显示或隐藏搜索面板 | `digup-shell --toggle` |

Hyprland 和 niri 不由应用自动注册全局快捷键；需要时把 `digup-shell --toggle` 绑定到桌面快捷键。
本次安装不修改现有按键。应用设置里显示的可执行路径也应使用公开的 `digup-shell` 入口，
避免指向 Nix 包内部的隐藏程序，绕过 GTK 和媒体插件环境。

Linux 与 Mac 的功能不完全相同；上游目前仅为 Mac 明确承诺截图文字 OCR 检索。
PDF 的页码跳转、媒体的时间点跳转还取决于对应默认查看器是否支持。

## 模型与硬件

官方发布包带 CPU 多版本后端（含 Zen 4）和 Vulkan 后端。
Nix 包提供 Vulkan 加载库，GPU 驱动沿用本机系统配置。
后端文件存在或包构建成功，都不等于已经在 Radeon 780M 上完成模型推理测试。

若实际索引遇到 GPU 错误，可在设置中尝试仅使用处理器，并保留日志以定位原因。
不需要为了安装此包改变内核、显卡驱动或网络配置。

## 数据与更新

| 内容 | 默认位置 |
| --- | --- |
| 模型与索引 | `~/.local/share/digup/` |
| 应用设置 | `~/.config/com.abdurrahim.DigUp/` |
| 应用数据 | `~/.local/share/com.abdurrahim.DigUp/` |

设置与数据由应用维护，不声明成 Home Manager 只读文件。
本包复用官方 `.deb` 的程序、助手、图标和许可证，通过 Nix 修正加载路径；不运行 Debian 安装脚本。
主程序使用锁定 nixpkgs 的 GTK、WebKit 和媒体插件，不需要 AppImage/FHS 环境。

`.deb` 构建的应用内更新入口只提供新版本提示和发布页，不替换 Nix store 文件。
升级应修改包的版本和 SHA-256、重建并检查，再手动应用系统配置。

独立构建（在包含本次改动的工作区）：

```bash
nix build path:.#digup --no-link -L
nix run path:.#digup
```

第二条命令会正式打开应用，并按首次设置流程下载模型。
仅构建包不会启动应用、下载模型或扫描个人文件。

## 故障排查

- **应用菜单未出现**：确认已经手动应用包含此包的 Home Manager 配置；单独 `nix build` 不会安装菜单入口。
- **快捷键没有反应**：先在终端运行 `digup-shell --toggle`，再检查当前桌面的绑定。
- **结果为空**：检查文件夹是否已选中、模型是否下载完成、索引是否暂停，以及文件是否属于支持的类型。
- **更新提示后未升级**：更新本地 Nix 包；不要使用 `.deb` 安装命令或手工替换 store 文件。
- **窗口、预览或输入法异常**：从终端运行 `digup-shell` 保留报错；真实 Wayland、中文输入和媒体播放仍需在当前桌面验证。

## 相关链接

- [上游项目与功能说明](https://github.com/ARahim3/DigUp)
- [固定版本发布记录](https://github.com/ARahim3/DigUp/releases/tag/v0.7.0-beta.3)
- [文件管理器](files.md)
- [Nix 手工打包](../dev/nix-packaging.md)
