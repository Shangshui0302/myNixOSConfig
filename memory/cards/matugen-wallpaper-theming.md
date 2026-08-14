---
id: matugen-wallpaper-theming
type: decision
tags: [matugen, wallpaper, theming, waypaper, noctalia, caelestia, hyprland, niri]
date: 2026-08-15
---

# 壁纸动态取色架构：matugen 单源多端分发

## 问题
希望壁纸切换时，动态取色同步 compositor 边框、shell 面板配色，且与 shell 解耦（不依赖 Noctalia）。

## 决策
壁纸由 waypaper + awww 管理（与 shell 解耦），切壁纸 → post_command → matugen 取色 → 一次写多端产物：

- **caelestia**：`~/.local/state/caelestia/scheme.json`（`Colours.qml` watchChanges 自动热载）
- **Noctalia**：`~/.config/noctalia/palettes/matugen.json`（`custom_palette = "matugen"`，需 config-reload）
- **Hyprland**：`hyprctl eval` 运行时下发 border 色（Lua provider 必须 eval，不落盘）
- **niri**：`~/.config/niri/wallpaper-colors.kdl`（include 自动热载）
- **DMS**：原生 `enableDynamicTheming`
- **foot**：不接管（保持 stylix 构建期）

构建期 stylix 作底色，运行时 matugen 覆盖（单一真源 = matugen 产物文件）。

## Why
- shell 解耦：配色由系统层 matugen 统一生成，shell 只是消费者，切 shell 不影响配色
- matugen 是 M3 取色引擎，Noctalia/caelestia 都用 M3 语义色（primary/secondary/surface），同源
- 构建期 stylix（base16）与运行时 matugen（M3）体系不同，保留 stylix 管 foot/底色，matugen 管动态覆盖

## How to apply
- 新增消费端：在 `matugen/*.tpl` 加模板 + `wallpaper.nix` 的 matugenConfig 加输出 + wrapper 加热载逻辑
- 颜色映射：active = primary、inactive = outline、locked = error
- 改全局配色只换壁纸；foot 配色仍走 stylix（不随壁纸）

相关: [[waypaper-nix-integration]] | [[noctalia-palette-format-reload]] | [[stylix-color-hub]] | [[foot-color-nohash]] | wiki/desktop/hyprland.md
