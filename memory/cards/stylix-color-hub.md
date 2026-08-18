---
id: stylix-color-hub
type: decision
tags: [stylix, colors, theming, noctalia, foot, hyprland, niri]
date: 2026-08-13
---

# stylix 作为配色中枢

## 问题
合成器/终端配色来源分散：Noctalia 模板分发 hyprland/niri 边框配色，foot 在 desktop.nix 手工配色，GTK 走 Material-Gnome（matugen 构建期取色）。配色源不统一。

## 决策
接入 stylix（`github:nix-community/stylix`）作为配色中枢：`config.lib.stylix.colors` 从壁纸（`assets/yamadaryou.png`）取色，foot/hyprland/niri 配色全部手工注入同一源。`autoEnable=false`（本版本 stylix master 无 foot/hyprland target，target 体系重构），不自动接管任何组件。

- **foot**：`home/de/foot.nix` 注入 stylix colors
- **hyprland**：`home/de/hyprland.nix` 生成 `hypr/stylix-colors.lua`，hyprland.lua `pcall(require, "stylix-colors")`
- **niri**：`home/de/niri.nix` 生成 `niri/stylix-colors.kdl`，config.kdl `include optional=true` 引入
- **Noctalia 合成器模板全停**：user（hyprland_lua/niri_colors）+ builtin hyprland 都停用。builtin hyprland 保留会在切主题时调用 `template-apply.sh hyprland`，创建 `hyprland.conf`（conf 格式）覆盖 stylix 的 lua 配色
- **GTK 保持 Material-Gnome**（matugen）、**Qt 保持 qt5ct/breeze**、**Noctalia 面板保持 yamadaryou** —— 与 stylix 分工协作

## Why
- 统一配色源：终端 foot 与合成器 border 同源（壁纸取色），改壁纸一处生效。
- stylix master 重构后无 foot/hyprland target，`config.lib.stylix.colors` 手工注入是最小改动路径。
- Noctalia 与 stylix 双管合成器配色会互相覆盖（Noctalia 切主题写 conf，conf 与 lua 配置冲突），故 Noctalia 合成器模板全部停用。

## How to apply
- 改全局配色：只改 `home/de/stylix.nix` 的 `image`（壁纸），rebuild 生效；`polarity` 控制暗色（当前 dark）。
- 不要重新启用 Noctalia 合成器模板（builtin_ids 里的 `hyprland` / user 模板）——会覆盖 stylix 注入。
- 新增需要配色的组件时，优先从 `config.lib.stylix.colors` 取色，与 foot/合成器同源。

相关: wiki/desktop/hyprland.md, wiki/desktop/niri.md, wiki/desktop/noctalia.md；[[mechrevo-amd-backlight-curve]]（壁纸同源 yamadaryou）
