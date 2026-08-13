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
- foot 配色注入用无前缀 hex：`config.lib.stylix.colors.baseXX`（而非 `withHashtag.baseXX`）。foot 的 `alpha` 单独保留（非颜色）。
- 背景/前景用 stylix 壁纸取色（`base00`/`base05`），**语法高亮 8 色（regular1-6/bright）用经典高对比 palette**——壁纸（金色系）取出的 base08-0F 区分度差，语法重点认不出。

## Why
- foot 1.27 颜色解析不接受 `#` 前缀（`foot -C --check-config` 实测：带 # 的 6/8 位都报错，无 # 通过）。
- stylix 壁纸取色的 base08-0F 会随壁纸主色偏（yamadaryou 金色系），作为终端语法高亮区分度差；终端可读性优先于"全量跟随壁纸"。

## How to apply
- foot 背景/前景用 `config.lib.stylix.colors.base00/base05`（无 #），语法色用经典红绿黄蓝紫青（`ff000f`/`8ce10b`/`ffb900`/`008df8`/`6d43a6`/`00d8eb`）
- 排查 foot 配置错误：`foot -C -c <config>` 快速校验
- hyprland/niri 的 border 色用 `withHashtag`（带 #）没问题，**只有 foot 要求无 #**

相关: [[stylix-color-hub]] | wiki/desktop/hyprland.md
