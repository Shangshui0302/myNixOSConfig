---
id: desktop-environment-host-hm-boundary
type: decision
tags: [desktop, home-manager, nixos, hyprland, niri]
date: 2026-08-18
---

# DE 目录语义与 Host/HM 边界

## 问题

仓库同时维护 Hyprland 和 niri。两者虽然都是 Wayland compositor，但配置目录还包含面板、终端、主题、启动会话和用户工具；继续使用 `hyprland/` 作为整套桌面目录会误导维护者，以为 niri 是 Hyprland 的附属配置。

## 决策

- 将整套主桌面环境统一放在 `host/de/` 与 `home/de/`。
- `host/de/` 只管理必须的系统集成：Hyprland 系统模块、XWayland、UWSM、Portal 和 greeter。
- `home/de/` 管理用户侧的 Hyprland、niri、Foot、Stylix、shell 和桌面变量。
- Hyprland 同时使用 NixOS 的 `programs.hyprland` 和 Home Manager 的 `wayland.windowManager.hyprland`；前者负责系统会话，后者负责用户配置。
- niri 使用 Home Manager 模块，但 Portal 保持在 Host 统一管理，避免两个层次重复注册或改变既有行为。

## Why

“DE”在这里表示一整套可启动、可使用的桌面环境，而不是某一个 compositor。NixOS 模块需要负责桌面会话入口和系统级集成，Home Manager 则适合声明用户配置；只用其中一层会分别丢失系统会话能力或用户配置管理能力。

## How to apply

- 新增 Hyprland/niri 用户配置放 `home/de/`，不要重新建立以某个 compositor 命名的平级整套目录。
- 新增会话入口、XWayland、UWSM、Portal 或登录器集成才放 `host/de/`。
- 先查 Home Manager 原生模块；若配置格式（如当前 Hyprland Lua）无法完整表达，再用 `xdg.configFile` 管理剩余配置。
- GNOME 仍通过 `specialisation/gnome/` 隔离，不应反向依赖 `home/de/`。

相关: [[wiki/architecture/index]] | [[wiki/desktop/hyprland]] | [[wiki/desktop/niri]] | [[memory/cards/gnome-specialisation]]
