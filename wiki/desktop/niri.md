---
title: Niri
category: desktop
tags: [wm, wayland, niri, scrolling-layout]
updated: 2026-08-10
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

配置由 Nix 生成（`home/env/niri.nix` → `~/.config/niri/config.kdl`），手动改会被 rebuild 覆盖（与 hyprland.lua 相同约定）。验证语法：`niri validate`。

要点：
- **显示器**：`output "eDP-1" { scale 1.5 }`（2K 屏，与 Hyprland 一致）
- **输入**：xkb `us` + `caps:escape`，触摸板 `natural-scroll`
- **圆角**：全局 `geometry-corner-radius 10` + `clip-to-geometry true`，focus-ring 跟随圆角
- **无 CSD**：`prefer-no-csd`，foot 等去掉标题栏，用 focus-ring 标焦点
- **Noctalia**：`spawn-at-startup "noctalia"` 自动拉起（原生支持 niri，通过 `NIRI_SOCKET` 检测）

## 键位（Mod = Super）

| 键位 | 功能 |
|------|------|
| Mod+W / E / B / N / O | foot / nautilus / chrome / nvim / obsidian |
| Mod+Space / C / K / Shift+Comma / Tab | Noctalia launcher / 剪贴板 / 控制中心 / 设置 / window-switcher |
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

## 配色同步（Noctalia）

niri 的 focus-ring 颜色由 Noctalia 模板渲染注入（与 hyprland-colors.lua 同机制）：

1. `home/env/noctalia.nix` 注册模板 `niri_colors`：`niri-colors.kdl` → `~/.config/niri/noctalia-colors.kdl`
2. 模板内容：`layout { focus-ring { active-color "{{colors.primary.default.hex}}" ... } }`
3. config.kdl 文件末尾 `include optional=true "~/.config/niri/noctalia-colors.kdl"`，Noctalia 改配色时 niri 热重载

## 已知差异（vs Hyprland）

- **blur 不是实时**：niri 默认 x-ray blur 只模糊壁纸一次（静态），窗口背后动态内容不实时模糊。Noctalia bar 的 blur 强制关闭（`layer-rule`），因为 x-ray blur 会错误模糊 bar 的透明部分
- **focus-ring 颜色** 由 Noctalia 注入（当前 yamadaryou 金色），不是 Hyprland 的 border
- **epic-mouse sensitivity**：niri 无逐设备等价项，未迁移

## 相关链接

- [Hyprland](hyprland.md) — 主力合成器
- [Noctalia](noctalia.md) — 面板（niri 原生支持）
- [wiki 首页](../README.md)
