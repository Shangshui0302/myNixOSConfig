---
title: Noctalia Shell
category: desktop
tags: [noctalia, shell, panel, wayland]
updated: 2026-11-20
---

# Noctalia Shell 使用指南

> **目录**
> 1. [面板布局](#面板布局)
> 2. [快捷键](#快捷键)
> 3. [鼠标操作](#鼠标操作)
> 4. [应用启动器](#应用启动器)
> 5. [控制中心](#控制中心)
> 6. [Dock](#dock)
> 7. [壁纸管理](#壁纸管理)
> 8. [配色方案 (Matugen)](#配色方案-matugen)
> 9. [锁屏与空闲](#锁屏与空闲)
> 10. [通知与 OSD](#通知与-osd)
> 11. [会话菜单](#会话菜单)
> 12. [常用操作流程](#常用操作流程)
> 13. [故障排查](#故障排查)
> 14. [相关链接](#相关链接)

Noctalia 是本机的桌面 Shell 环境，替代传统的顶栏、Dock、应用启动器等组件，提供壁纸入口、配色显示、通知与锁屏等功能。

**启动方式**：由 systemd user service（`noctalia.service`）承载，但不是 compositor autostart，也**不再自挂 `graphical-session.target`**——拉起哪个 shell 由 `shell-switcher-boot.service`（`shell-switcher boot`，读 `~/.config/shell-switcher/current` 标记）唯一决定。原因：uwsm 会话下 `graphical-session.target` 会并行启动所有 `WantedBy` 单元，而 shell-switcher 只停它自己启动的 shell，Noctalia 自启会与 Caelestia 并存。详见 [shell-switcher](shell-switcher.md)。

**模块来源**：使用锁定的 Noctalia Home Manager 模块。该模块已经屏蔽 HM 自带模块的旧文件路径和新目录路径，本地无需再声明 `disabledModules`。

## 面板布局

顶栏分三个区域：

| 区域 | Widget | 说明 |
|------|--------|------|
| 左 | 启动器、Nix Monitor、CPU | 应用入口、更新状态与系统负载 |
| 左 | 时钟、天气 | 日期时间与天气 |
| 中 | Bangumi Progress、Token Monitor、GitHub Kanban | 追番进度、用量与 GitHub 看板 |
| 中 | 工作区 | 显示工作区状态 |
| 右 | 媒体 / 音频可视化 | 播放时显示进度和可视化效果 |
| 右 | 音量、亮度、网络 | 悬停展开或打开对应控制中心面板 |
| 右 | 剪贴板、Screen Toolkit、通知、Mihomo | 常用面板与状态入口 |
| 右 | 隐私、Phone Operate、电池/会话 | 设备状态和会话菜单 |
| 右 | 系统托盘 | 固定 Chrome 图标，抽屉收纳其余 |

顶栏：透明外层、0.8 胶囊不透明度，始终保留胶囊布局。

> **维护**：2026-08-13 清理 `noctalia config validate` 的 4 个 warning（`home/de/noctalia.nix`）：bongocat 宠物插件、launcher session 搜索因新版不再识别已移除；网络指示器字段更新为新版（`visualization/show_value/show_glyph`）。现有功能（上传/下载速率等）保持不变。

## 快捷键

Hyprland 和 niri 的 Shell 操作通过 `desktop-shell-action` 分发给当前 Shell。

| 按键 | 功能 |
|------|------|
| `Super + Space` | 应用启动器 |
| `Super + Alt + K` | 控制中心 |
| `Super + ,` | 设置面板 |
| `Super + ?` | Hyprland 的 Keybind Cheatsheet；niri 显示原生快捷键帮助 |
| `Super + Tab` | Hyprland 的 ScrollOverview；niri 使用原生 `toggle-overview`，不经过 Noctalia |
| `Super + C` / `Super + Shift + C` | 剪贴板面板 / 清空 Noctalia 剪贴板历史 |

Noctalia 自带的 `window_switcher` 不再作为总览入口；Hyprland 左下角热角保留为自定义 ScrollOverview 命令。

## 鼠标操作

| 操作 | 行为 |
|------|------|
| 滚轮（顶栏空白处） | 切换工作区 |
| 中键（顶栏空白处） | 打开设置 |
| 右键（顶栏空白处） | 打开控制中心（跟随鼠标） |

## 应用启动器

- **打开方式**：`Super + Space` 或点击顶栏 🚀 图标
- **剪贴板历史**：已启用，支持文本和图片，自动预览
- **固定应用**：Strata（启动器）；Dock 固定 Strata、Codex Desktop、Google Chrome
- **启动器提供者**：Emoji、Session、Windows 均启用
- **排序**：按使用频率排序
- **视图模式**：列表，显示分类
- **终端命令**：foot

启动器继承 systemd 用户会话的 PATH，不再用固定目录列表覆盖。`gdbus` 由用户
profile 提供，保留手机操作功能；从菜单启动的 Paseo 等应用也能找到 Home Manager
配置的 DSH 和用户命令目录。

## 控制中心

点击顶栏最右侧图标或 `Super + Alt + K` 打开。

**左侧快捷操作：**
| 项目 | 说明 |
|------|------|
| Network | WiFi 管理（列表视图）、蓝牙管理、飞行模式 |
| Bluetooth | 蓝牙设备管理，自动连接已配对设备 |
| WallpaperSelector | 壁纸选择器 |
| NoctaliaPerformance | 性能模式（禁用桌面小组件） |
| Screen Toolkit | 屏幕取色、OCR |

**右侧快捷操作：**
| 项目 | 说明 |
|------|------|
| PowerProfile | 电源方案切换 |
| KeepAwake | 阻止自动休眠 |
| NightLight | 夜间色温（已配置自动调度） |
| Color Scheme Creator | 配色方案生成器 |

**卡片区域：** Profile、Shortcuts、Audio、Brightness、Network、Weather、Media/Sysmon

## 插件依赖与设置

- **Screen Toolkit**：截图、OCR、二维码、录屏和翻译工具由 `home/productivity/graphics.nix` 提供；OCR 启用中、英、日、韩、俄五种模型，录屏后端使用 `wl-screenrec`。截图目录由 Noctalia 的 `shell.screenshot.directory` 统一管理，插件不再支持 `screenshot-path`。
- **Phone Operate**：`adb`、scrcpy、SSHFS 由 `home/productivity/phone.nix` 提供；主桌面的 KDE Connect 与发现端口由 `host/base/desktop.nix` 管理。
- **Translator**：默认翻译目标为中文；Google 模式没有本地命令依赖。

- **插件来源**：个人 `Shangshui0302/community-plugins` fork 排在 official、community 之前，与界面覆盖中的顺序一致。
- **GitHub Kanban**：通知已读状态采用 `synced`，仓库使用网格布局。
- **Token Monitor**：使用本机 `127.0.0.1:17321`，每 60 秒刷新；凭据文件仅引用容器目录路径，内容不进入 Nix。
- **配置同步**：界面覆盖位于 `~/.local/state/noctalia/settings.toml`，优先于 Nix 生成的 `~/.config/noctalia/config.toml`。2026-11-03 已把非敏感偏好及额外 TOML 的 Token Monitor 设置同步到 `home/de/noctalia.nix`；本地覆盖仍保留。Nix 中已清理停用的 GitHub Activity、Obsidian、Git Companion 定义及顶栏占位；本机覆盖中的旧定义仍需通过设置界面清除。Mihomo 密钥、当前主题模式和壁纸状态不纳入此次同步。

## Dock

- **位置**：底部；关闭强制自动隐藏，启用智能自动隐藏
- **固定应用**：Strata、Codex Desktop、Google Chrome、VS Code、Foot
- **启动器图标**：使用发行版 Logo
- **分组**：同一应用窗口合并，圆点指示器，点击列表切换
- **行为**：仅显示当前屏幕的应用

## 壁纸管理

壁纸已由 **waypaper + awww** 统一管理（与 shell 解耦，见 [Hyprland](hyprland.md) 的壁纸动态取色），Noctalia 不再切壁纸（`wallpaper.enabled = false`）。`~/Pictures/Wallpapers/` 是用户可写的 Git 壁纸仓库；Nix 只用 `assets/nixos_logo.png` 作为构建期和首次初始化的默认壁纸，不向仓库创建软链接。

## 配色方案 (matugen)

当前主题：**matugen**——waypaper 切壁纸后生成 `~/.config/noctalia/palettes/matugen.json`，由 `theme.custom_palette = "matugen"` 消费。模板全部禁用，Noctalia 只读取 Matugen 产物。主桌面的 GTK、Hyprland 与 niri 也由同一次 Matugen 运行更新；Foot 仍使用 `home/de/foot.nix` 定义的固定深色配色。Matugen 产物按壁纸内容缓存，回到已使用过的壁纸时不再重新取色；日志中的 `cache=hit source=wallpaper` 表示显式壁纸路径复用了已有产物。

深浅模式由 Darkman 管理。Noctalia 启动时和每次 Darkman 切换后都会同步当前模式，但不会反向修改系统主题；使用 `Super + Shift + D` 或 `darkman toggle` 切换。`theme-apply` 在复制 palette 后立即发送 `theme-mode-set`，再处理可能耗时数秒的 Papirus 文件夹重着色；这样壁纸重点色不会等待图标处理完成。palette 文件变化由 Noctalia 文件监听器负责 reload，不再重复发送 `config-reload`。若 `matugen.json` 被删，下次主题应用会从完整缓存补回；文件内容一致时不会重写，也不会因深浅切换而触发文件监听。

## 锁屏与空闲

| 事件 | 时间 | 说明 |
|------|------|------|
| 屏幕关闭 | 600 秒（10 分钟） | 5 秒淡出过渡 |
| 自动锁定 | 660 秒（11 分钟） | 屏幕关闭后 60 秒 |
| 自动休眠 | 1800 秒（30 分钟） | 锁定后 19 分钟 |

- 锁屏：模糊背景约 0.8，内屏与 HDMI-A-1 各自保存登录框布局；允许提交空密码给认证后端（不会跳过认证）
- 倒计时 10 秒，显示会话按钮（锁屏/休眠/重启/关机/注销）
- 锁屏媒体控件：已启用

## 通知与 OSD

| 项目 | 设置 |
|------|------|
| 位置 | 右下角 |
| 密度 | 紧凑 |
| 低/普通/紧急 | 3s / 8s / 15s |
| 媒体切换提示 | 启用 |
| 键盘布局提示 | 启用 |
| 电池提示 | 启用 |
| OSD 位置 | 顶部，2 秒自动消失 |

## 会话菜单

关机/重启/休眠/注销/锁定，支持倒计时 5 秒，居中显示。

## 常用操作流程

### 切换深浅模式

```
Super + Shift + D  # Darkman 切换暗色/亮色
# 或 darkman set dark / darkman set light
```

### 更换壁纸

```
Super + Alt + K        # 控制中心
WallpaperSelector # 浏览壁纸目录
点击选择          # 带过渡动画切换
```

### 查看系统性能

```
顶栏左侧系统监视器  # 实时 CPU/内存
Super + Alt + K → Media/Sysmon 卡片  # 详细信息
```

### 使用 AI 助手

```
点击顶栏 AI 助手面板     # 右侧弹出面板
输入问题                 # Gemini 2.5 Flash 回复
# 支持实时翻译（Google，自动检测→英文）
```

## 故障排查

若终端能找到命令、菜单启动的应用却找不到，先比较 `systemctl --user show-environment`
中的 PATH 与目标进程的 PATH。应用此修复后重新登录，再启动 Paseo；
`paseo provider diagnostic deepseek-harness` 可检查 dsh 是否被发现。

```bash
# 重启 Noctalia Shell
pkill noctalia-shell; noctalia-shell &

# 查看日志
journalctl --user -u noctalia-shell -f

# 强制切换暗色模式
noctalia-shell ipc call darkMode setDark
noctalia-shell ipc call darkMode setLight
```

## 相关链接

- [Hyprland](hyprland.md) — 快捷键与面板绑定、边框颜色跟随主题
- [深色模式架构](darkmode.md) — Noctalia 是唯一深色调度器，hook 写 dconf/qt5ct
- [Shell 环境](shell.md) — 环境变量、应用启动器终端命令
- [wiki 首页](../README.md)
