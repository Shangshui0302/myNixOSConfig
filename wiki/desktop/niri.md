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

包：`niri`（nixpkgs，`home/env/niri.nix`）。配置放 `~/.config/niri/config.kdl`，尚未启用。

## 与 Hyprland 的关系

| 项目 | Hyprland | Niri |
|------|----------|------|
| 布局 | 平铺 + 浮动 + 特殊工作区 | 纯滚动流（一维） |
| 配置 | Lua (`hyprland.lua`) | KDL (`config.kdl`) |
| 依赖 Noctalia | 有（面板联动） | 无 |

Niri 目前仅安装，未配置面板。后续 shell 阶段评估 DMS-shell 对 niri 的一等公民支持时再深入。

## 相关链接

- [Hyprland](hyprland.md) — 主力合成器
- [wiki 首页](../README.md)
