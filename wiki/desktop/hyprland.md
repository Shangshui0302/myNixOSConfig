---
title: Hyprland
category: desktop
tags: [wm, wayland, hyprland, scrolling-layout, workspace-overview]
updated: 2026-09-03
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

Hyprland 的 shell 相关快捷键经 `desktop-shell-action` 按 active service 分发，切换到 Caelestia 后仍使用同一套按键；壁纸和 Matugen 配色继续沿用主桌面的统一管线。

**配色（stylix）**：`home/theme/stylix.nix` 接入 stylix（`github:nix-community/stylix`）作为配色中枢，`config.lib.stylix.colors` 从壁纸取色。foot 配色在 desktop.nix 手工注入：**背景/前景用 stylix 壁纸取色，语法高亮 8 色用经典高对比 palette**（壁纸金色系取色区分度差，认不出语法重点；foot 1.27 不接受 `#` 前缀，全部无前缀 hex）；hyprland/niri 配色手工注入（border 色）。foot 字体 `Anthropic Mono Variable:size=12`（stylix 接入时曾被误删、字号退回默认，已恢复）。

**壁纸动态取色**：壁纸由 waypaper + awww 管理；切壁纸时 post_command 触发 Matugen（`-t scheme-content`）一次生成 Caelestia、Noctalia、Hyprland/niri、GTK 和 Qt 的配色。Noctalia palette 写完后会 `config-reload`；Hyprland 边框由 `hyprctl eval` 运行时下发，niri include 自动重读；Material-Gnome 的主桌面副本直接更新 `colors.css`，GTK 应用随即刷新；Qt5/Qt6 共用 qtct 调色板，新启动的 Qt 应用读取最新颜色。Foot 仍由 Stylix 管理，不随壁纸改变。

## 基本概念

### 滚动布局 (Scrolling Layout)

窗口按列排列，新窗口自动成为主列（master）。列数随窗口增多自动扩展，工作区内容超出屏幕时可以左右滚动。

- 列宽分布：33% → 50% → 67% → 81% → 96%（随窗口数递增）
- 焦点跟随滚动
- 全屏应用独占一列

### 工作区

共 10 个工作区（1–10），外加一个特殊工作区（scratchpad）。

### 工作区总览 (ScrollOverview)

`Super + G` 打开或关闭 ScrollOverview。它以纵向缩略图显示所有工作区，选择窗口后返回当前布局；插件由 Nix 随 Hyprland 加载，不需要手动运行 `hyprpm`。

---

## 快捷键

> `Super` = Win/Command 键

### 启动应用

| 按键 | 功能 |
|------|------|
| `Super + W` | 终端 (foot) |
| `Super + E` | 文件管理器 (Nautilus) |
| `Super + C` | 剪贴板（Noctalia 面板 / Caelestia 的 Clipse） |
| `Super + Space` | 应用启动器（Noctalia / Caelestia） |
| `Super + K` | 控制中心（Noctalia / Caelestia utilities） |
| `Super + ,` | 设置面板（Noctalia / Caelestia Nexus） |
| `Super + Tab` | 窗口切换（Noctalia window switcher / Caelestia 下一个窗口） |
| `Super + Shift + D` | Darkman 切换深浅模式 |

### 截图

| 按键 | 功能 |
|------|------|
| `Print` | 全屏截图（自动保存 + 复制到剪贴板） |
| `Shift + Print` | 区域截图（Swappy 编辑后保存 + 复制） |

截图保存在 `~/Pictures/Screenshots/YYYY-MM/` 目录下。

### 窗口管理

| 按键 | 功能 |
|------|------|
| `Super + Q` | 关闭窗口 |
| `Super + V` | 浮动 / 平铺切换 |
| `Super + F` | 全屏切换 |
| `Super + P` | 伪平铺（保持窗口位置但参与布局） |

### 焦点与工作区

| 按键 | 功能 |
|------|------|
| `Super + ←/→/↑/↓` | 切换焦点 |
| `Super + 1–0` | 切换到工作区 1–10 |
| `Super + G` | 打开 / 关闭 ScrollOverview 工作区总览 |
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
| `Fn + F5` / `XF86TouchpadToggle` | 切换触控板 |
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
2. **桌面 Shell** — 默认 Noctalia，切换后由 Caelestia 接管顶栏/面板
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

边框颜色由 stylix 注入（壁纸取色，与 foot 终端同源），见 `home/theme/stylix.nix`。Noctalia 切主题不影响合成器边框。

当前主题：**NixOS 默认壁纸 / Matugen 动态配色**

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

### WUJIE14XA 触控板 Fn 键

WUJIE14XA 的 `Fn + F5` 应进入 `XF86TouchpadToggle`。Hyprland 通过 HM 生成的 `toggle-touchpad` 脚本切换实际设备 `uniw0001:00-093a:0255-touchpad`；脚本只保存当前用户会话的启用状态，不读写 EC。`atkbd` 日志中的 `e078` 未作为未知键映射，避免误伤其他 Fn 键。

### 亮度调到最高反而变黑

AMD 核显（Radeon 780M）内核 6.15+ 的 custom brightness curve 在顶端溢出、100% 亮度变全黑。已在 `host/base/boot.nix` 用内核参数 `amdgpu.dcdebugmask=0x40000` 禁用该曲线修复（需 reboot。为何不升内核见 `memory/cards/mechrevo-amd-backlight-curve.md`）。若重现，验证：

```
cat /sys/module/amdgpu/parameters/dcdebugmask   # 应为 262144
```

## 相关链接

- [Noctalia](noctalia.md) — 顶栏/控制中心/应用启动器，快捷键与 Hyprland 绑定
- [Shell 环境](shell.md) — `Super + W` 启动的 foot 终端配置
- [深色模式架构](darkmode.md) — Darkman 模式状态；合成器边框由 Matugen 运行时覆盖 Stylix 底色
- [ScrollOverview](https://github.com/yayuuu/hyprland-scroll-overview) — Hyprland 工作区总览插件
- [Memory: ScrollOverview 的 Nix 接入](../../memory/cards/hyprland-scrolloverview-plugin.md) — 版本匹配与显式加载原因
- [Memory: AMD 背光曲线溢出](../../memory/cards/mechrevo-amd-backlight-curve.md) — 100% 亮度变黑的内核参数修复
- [Memory: WUJIE14XA Fn 输入链路](../../memory/cards/mechrevo-wujie14xa-fn-input.md) — 触控板 Fn 的 Hyprland 用户态处理
- [Memory: Hyprland 模糊 / AMD 780M](../../memory/cards/hyprland-056-blur-amd.md) — 模糊在 AMD 核显失效的处理
- [wiki 首页](../README.md)
