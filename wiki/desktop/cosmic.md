---
title: COSMIC
category: desktop
tags: [de, wayland, cosmic, system76]
updated: 2026-08-11
---

# COSMIC 桌面环境

COSMIC 是 System76 用 Rust 开发的桌面环境（iced + Smithay），面向 POP!_OS，nixpkgs 支持处于 in-development/beta。作为**独立变量**存在：自带完整 session 管理（cosmic-session），不依赖 uwsm，也不依赖 GDM/greetd。

## 配置

`host/cosmic.nix`：

```nix
services.desktopManager.cosmic.enable = true;
environment.cosmic.excludePackages = [ pkgs.orca ];  # 排除屏幕阅读器
```

要点：
- **cosmic-greeter 不启用**（`services.displayManager.cosmic-greeter.enable` 默认 false）——保持 kmscon 纯 TTY 登录，不引入 greetd
- COSMIC 自带 systemd session（cosmic-session.target），**不要用 `uwsm start`**，会重复 session 管理

## 启动

TTY 登录后直接：

```bash
start-cosmic
```

start-cosmic 是自足会话入口：设置 `XDG_SESSION_TYPE=wayland`、`XDG_CURRENT_DESKTOP=COSMIC` 等环境变量，拉起 cosmic-comp + cosmic-shell 全家。

## 特性与注意

- 配置是 RON 文件（`~/.config/cosmic/`），NixOS 无声明式 option
- 锁屏依赖 `security.pam.services.cosmic-greeter`（模块自动配置，无需手动）
- 生态：cosmic-applets/library/term 等全套 System76 应用
- 版本 1.5.0（2026-08）

## 与 Hyprland/niri 的关系

| 项目 | Hyprland | niri | COSMIC |
|------|----------|------|--------|
| 类型 | 合成器 | 合成器 | 完整 DE |
| 启动 | uwsm | uwsm | start-cosmic |
| 配置 | Lua | KDL | RON |
| 背景 | 社区 | 个人 | System76 公司 |

COSMIC 作为"有商业公司兜底的完整 DE"补充 Hyprland/niri。

## 相关链接

- [Hyprland](hyprland.md) — 主力合成器
- [Niri](niri.md) — 滚动平铺合成器
- [wiki 首页](../README.md)
