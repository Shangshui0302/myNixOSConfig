---
title: Hyprland
category: desktop
tags: [wm, wayland, hyprland, scrolling-layout]
updated: 2026-08-13
---

# Hyprland 使用指南

> **目录**
> 1. [基本概念](#基本概念)
> 2. [快捷键](#快捷键)
> 3. [触控板手势](#触控板手势)
> 4. [启动时自动运行](#启动时自动运行)
> 5. [常用工作流](#常用工作流)
> 6. [主题](#主题)
> 7. [故障排查](#故障排查)
> 8. [相关链接](#相关链接)

本机 Hyprland 配置基于 Lua (`~/.config/hypr/hyprland.lua`)，使用 **scrolling layout**（滚动列布局）。

**桌面 shell 切换**：默认 Noctalia（systemd 拉起；默认 shell 由 config.toml 的 `default` 指定），可运行时切到 Caelestia：`shell-switcher set caelestia|noctalia`（切换器配置 `~/.config/shell-switcher/config.toml`，见 `home/de/shell-switcher.nix`）。两个 shell 的 service 由切换器互斥启停，避免抢占 `org.freedesktop.Notifications` DBus。shell-switcher 二进制经 flake input 接入（`github:Shangshui0302/shell-switcher`）。

**配色（stylix）**：`home/de/stylix.nix` 接入 stylix（`github:nix-community/stylix`）作为配色中枢，`config.lib.stylix.colors` 从壁纸取色。foot 配色在 desktop.nix 手工注入：**背景/前景用 stylix 壁纸取色，语法高亮 8 色用经典高对比 palette**（壁纸金色系取色区分度差，认不出语法重点；foot 1.27 不接受 `#` 前缀，全部无前缀 hex）；hyprland/niri 配色手工注入（border 色）。foot 字体 `Anthropic Mono Variable:size=12`（stylix 接入时曾被误删、字号退回默认，已恢复）。

**壁纸动态取色**：壁纸由 waypaper + awww 管理（swww 在 nixpkgs 改名 awww，同作者继任，与 shell 解耦），切壁纸时 post_command 触发 matugen 取色（`-t scheme-content`，与 Noctalia m3-content 同源），一次生成多端产物：caelestia `~/.local/state/caelestia/scheme.json`（`Colours.qml` watchChanges 自动热载）、Noctalia `~/.config/noctalia/palettes/matugen.json`（`custom_palette = "matugen"`）。Noctalia 的 palette 文件不被 file_watcher 监听，分发脚本在 matugen 写完后触发 `noctalia msg config-reload` 让它重读换色。waypaper `config.ini` 用可写副本（Nix symlink 只读报 "permission error"）且 section 必须 `[Settings]`（大写），并预设 `folder = ~/Pictures/Wallpapers`（否则 waypaper 每次打开回退默认 Pictures 需重选）。post_command 指向固定路径 `~/.local/bin/wallpaper-theme`（waypaper 常驻进程会缓存 post_command 并写回 config.ini，store hash 路径每次 rebuild 变导致值漂移，固定路径 + activation 更新内容解决）。**Hyprland 边框**由分发脚本 `hyprctl eval` 运行时下发（Lua provider 下必须 eval，改 general/group 的 border 色，不落盘不破坏 Nix）；**niri 边框**由 matugen 直接写 `~/.config/niri/wallpaper-colors.kdl`（niri include 自动热载）。实现见 `home/de/wallpaper.nix` + `matugen/*.tpl`。GTK 保持 Material-Gnome、Qt 保持 qt5ct/breeze。

## 基本概念

### 滚动布局 (Scrolling Layout)

窗口按列排列，新窗口自动成为主列（master）。列数随窗口增多自动扩展，工作区内容超出屏幕时可以左右滚动。

- 列宽分布：33% → 50% → 67% → 81% → 96%（随窗口数递增）
- 焦点跟随滚动
- 全屏应用独占一列

### 工作区

共 10 个工作区（1–10），外加一个特殊工作区（scratchpad）。

---

## 快捷键

> `Super` = Win/Command 键

### 启动应用

| 按键 | 功能 |
|------|------|
| `Super + Q` | 终端 (foot) |
| `Super + E` | 文件管理器 (Nemo) |
| `Super + Space` | 应用启动器 (Noctalia) |
| `Super + K` | 控制中心 (Noctalia) |
| `Super + ,` | 设置面板 (Noctalia) |
| `Super + Tab` | 工作区总览 (Noctalia) |

### 截图

| 按键 | 功能 |
|------|------|
| `Print` | 全屏截图（自动保存 + 复制到剪贴板） |
| `Shift + Print` | 区域截图（Swappy 编辑后保存 + 复制） |

截图保存在 `~/Pictures/Screenshots/YYYY-MM/` 目录下。

### 窗口管理

| 按键 | 功能 |
|------|------|
| `Super + W` | 关闭窗口 |
| `Super + V` | 浮动 / 平铺切换 |
| `Super + F` | 全屏切换 |
| `Super + P` | 伪平铺（保持窗口位置但参与布局） |

### 焦点与工作区

| 按键 | 功能 |
|------|------|
| `Super + ←/→/↑/↓` | 切换焦点 |
| `Super + 1–0` | 切换到工作区 1–10 |
| `Super + S` | 切换特殊工作区（scratchpad） |
| `Super + Shift + S` | 移动窗口到特殊工作区 |

### 窗口移动 / 缩放 / 交换

| 按键 | 功能 |
|------|------|
| `Super + Ctrl + ←/→/↑/↓` | 调整窗口大小 |
| `Super + Ctrl + 0–9` | 调整窗口大小为 10% 增量预设（1920×1200 逻辑像素） |
| `Super + Shift + ←/→/↑/↓` | 移动窗口 |
| `Super + Alt + ←/→/↑/↓` | 交换窗口位置 |
| `Super + Shift + 1–0` | 窗口移到工作区 1–10 |

### 退出

| 按键 | 功能 |
|------|------|
| `Super + Shift + M` | 退出 Hyprland |

### 媒体 & 亮度

| 按键 | 功能 |
|------|------|
| 音量 +/- | 调整 2% |
| 静音 | 切换静音 |
| 麦克风静音 | 切换麦克风 |
| 亮度 +/- | 调整亮度 |

### 鼠标操作

| 操作 | 功能 |
|------|------|
| `Super + 滚轮` | 切换工作区 |
| `Super + 左键拖拽` | 拖动窗口 |
| `Super + 右键拖拽` | 调整窗口大小 |

---

## 触控板手势

| 手势 | 功能 |
|------|------|
| 三指上下滑动 | 切换工作区 |
| 三指左右滑动 | 平滑滚动列 |

---

## 启动时自动运行

1. **fcitx5** — 输入法
2. **Noctalia Shell** — 顶栏/侧边栏面板
3. **HVE Watchdog** — Noctalia 主题热加载守护进程

---

## 常用工作流

### 打开应用 -> 排列窗口

```
Super + Space   # 启动器搜索应用
Super + Shift + ←/→  # 调整窗口位置
Super + Ctrl + ←/→   # 调整窗口大小
```

### 多工作区管理

```
Super + 2       # 跳到工作区 2
Super + Shift + 3  # 把当前窗口移到工作区 3
Super + 鼠标滚轮   # 快速浏览工作区
```

### 小窗 / 浮动

```
Super + V       # 切换浮动（计算器、弹窗等）
Super + S       # 临时收纳到 scratchpad
Super + S       # 再按一次唤出
```

### 截图工作流

```
Print           # 全屏截图，自动存文件 + 进剪贴板
Shift + Print   # 区域截图 → Swappy 标注 → 存文件 + 剪贴板
```

---

## 主题

边框颜色由 stylix 注入（壁纸取色，与 foot 终端同源），见 `home/de/stylix.nix`。Noctalia 切主题不影响合成器边框。

当前主题：**yamadaryou**

---

## 故障排查

```
# 验证配置文件语法
hyprland --verify-config

# 查看 Hyprland 日志
cat /tmp/hypr/$(ls -t /tmp/hypr/ | head -1)/hyprland.log

# 重新加载配置（不重启）
hyprctl reload
```

### 亮度调到最高反而变黑

AMD 核显（Radeon 780M）内核 6.15+ 的 custom brightness curve 在顶端溢出、100% 亮度变全黑。已在 `host/base/boot.nix` 用内核参数 `amdgpu.dcdebugmask=0x40000` 禁用该曲线修复（需 reboot。为何不升内核见 `memory/cards/mechrevo-amd-backlight-curve.md`）。若重现，验证：

```
cat /sys/module/amdgpu/parameters/dcdebugmask   # 应为 262144
```

## 相关链接

- [Noctalia](noctalia.md) — 顶栏/控制中心/应用启动器，快捷键与 Hyprland 绑定
- [Shell 环境](shell.md) — `Super + Q` 启动的 foot 终端配置
- [深色模式架构](darkmode.md) — Noctalia 深色调度（合成器边框配色归 stylix）
- [Memory: AMD 背光曲线溢出](../../memory/cards/mechrevo-amd-backlight-curve.md) — 100% 亮度变黑的内核参数修复
- [Memory: Hyprland 模糊 / AMD 780M](../../memory/cards/hyprland-056-blur-amd.md) — 模糊在 AMD 核显失效的处理
- [wiki 首页](../README.md)
