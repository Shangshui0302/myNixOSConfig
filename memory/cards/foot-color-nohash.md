---
id: foot-color-nohash
type: constraint
tags: [foot, terminal, stylix, colors]
date: 2026-08-13
---

# foot 颜色不接受 `#` 前缀（用无前缀 hex）

## 问题
foot 1.27 启动时报 `[colors-dark].background: #1a1b29: color must be in RGB format`——带 `#` 前缀的 6 位/8 位 hex 全被拒绝。stylix 注入 foot 配色用了 `withHashtag`（带 `#`），导致 foot 配置无效。

## 决策
foot 配色注入用无前缀 hex：`config.lib.stylix.colors.baseXX`（而非 `config.lib.stylix.colors.withHashtag.baseXX`）。foot 的 `alpha` 单独保留（非颜色）。

## Why
foot 1.27 的颜色解析不接受 `#` 前缀（`foot -C --check-config` 实测：带 # 的 6/8 位都报错，无 # 通过）。stylix 默认给的 `withHashtag` 系列在此不可用。

## How to apply
- 给 foot 注入颜色，用 `config.lib.stylix.colors.baseXX`（无 #）
- 排查 foot 配置错误：`foot -C -c <config>` 快速校验
- hyprland/niri 的 border 色用 `withHashtag`（带 #）没问题，**只有 foot 要求无 #**

相关: [[stylix-color-hub]] | wiki/desktop/hyprland.md
