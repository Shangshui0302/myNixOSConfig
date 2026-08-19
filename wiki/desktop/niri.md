---
title: Niri
category: desktop
tags: [wm, wayland, niri, scrolling-layout]
updated: 2026-08-19
---

# Niri 使用指南

Niri 是滚动平铺 Wayland 合成器（scrollable-tiling window layout），窗口沿一条无限纵向流排列，通过滚动切换窗口而非工作区。与 Hyprland 平级，都是通过 uwsm 启动的 compositor。

## 启动与切换

```bash
# TTY 登录后启动 niri（uwsm 通过 wayland-sessions/niri.desktop 自动发现）
uwsm start niri

# 注销当前 compositor
uwsm stop
```

Hyprland ↔ niri 切换：注销当前 compositor → 切到其他 TTY 重新登录 → `uwsm start <另一个>`。

## 配置

配置由 Nix 生成（`home/de/niri.nix` → `~/.config/niri/config.kdl`），手动改会被 rebuild 覆盖（与 hyprland.lua 相同约定）。验证语法：`niri validate`。

要点：
- **显示器**：`output "eDP-1" { scale 1.5 }`（2K 屏，与 Hyprland 一致）
- **输入**：xkb `us` + `caps:escape`，触摸板 `natural-scroll`
- **圆角**：全局 `geometry-corner-radius 10` + `clip-to-geometry true`，focus-ring 跟随圆角
- **无 CSD**：`prefer-no-csd`，foot 等去掉标题栏，用 focus-ring 标焦点
- **Noctalia**：由 Home Manager 声明的 user service 随图形会话启动；不在 niri 配置中重复 `spawn-at-startup`

## 键位（Mod = Super）

| 键位 | 功能 |
|------|------|
| Mod+W / E / B / N / O | foot / nautilus / chrome / nvim / obsidian |
| Mod+Space / C / K / Shift+Comma / Tab | Noctalia launcher / 剪贴板 / 控制中心 / 设置 / window-switcher |
| Mod+Shift+D | Darkman 切换深浅模式 |
| Mod+Q / F / V / Shift+M / Shift+W | 关闭 / 全屏 / 浮动 / 退出 / tabbed-display |
| Mod+方向键 | 聚焦（列/窗口） |
| Mod+Ctrl+方向键 | 移动（列/窗口） |
| Mod+1..0 | 工作区（Ctrl 移动） |
| Mod+滚轮 | 切工作区 |
| Mod+Minus/Equal | 列宽 ±10%（Shift 为窗口高度） |
| Mod+R / Ctrl+Shift+R | 循环预设列宽 / 窗口高度 |
| Mod+Ctrl+F | 扩展列到可用宽度 |
| Mod+BracketLeft/Right | consume/expel 窗口出入列 |
| Print / Shift+Print | 截图（复用 hyprland 脚本） |
| XF86 音量/亮度 | PipeWire / Noctalia |

## 配色（stylix 底色 + matugen 动态）

niri 的 focus-ring 颜色分两层：

1. **stylix 构建期底色**：`niri/stylix-colors.kdl`（壁纸取色，与 foot 同源），rebuild 生效
2. **matugen 动态覆盖**：`~/.config/niri/wallpaper-colors.kdl`——切壁纸时 matugen 直接写该文件，niri 的 include 监视自动热载换色（active = primary，inactive = outline）

config.kdl 末尾依次 `include` stylix-colors.kdl 和 wallpaper-colors.kdl（后者位置序覆盖前者）。改配色切壁纸即可，无需 rebuild。

> Noctalia 不再分发 niri 配色（`niri_colors` 模板已停用），切 Noctalia 主题不影响 niri focus-ring。

## 已知差异（vs Hyprland）

- **blur 不是实时**：niri 默认 x-ray blur 只模糊壁纸一次（静态），窗口背后动态内容不实时模糊。Noctalia bar 的 blur 强制关闭（`layer-rule`），因为 x-ray blur 会错误模糊 bar 的透明部分
- **focus-ring 颜色** 由 stylix 注入（壁纸取色），不是 Hyprland 的 border
- **epic-mouse sensitivity**：niri 无逐设备等价项，未迁移

## 相关链接

- [Hyprland](hyprland.md) — 主力合成器
- [Noctalia](noctalia.md) — 面板（niri 原生支持）
- [wiki 首页](../README.md)
