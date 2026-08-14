---
id: noctalia-palette-format-reload
type: constraint
tags: [noctalia, palette, matugen, colors]
date: 2026-08-15
---

# Noctalia palette 格式与热载

## 问题
matugen 生成 Noctalia palette 时踩了两个坑：颜色值无 `#` 前缀导致一片黑；palette 文件更新后 Noctalia 不自动换色。

## 决策 / 坑
1. **palette 颜色值必须带 `#` 前缀**：Noctalia 的 palette（yamadaryou 等）值带 `#`（如 `"#ffec15"`）。matugen 模板用 `hex_stripped`（无 #）生成的值 Noctalia 解析失败 → 一片黑。Noctalia palette 模板用 `{{colors.*.hex}}`（带 #），而 caelestia 用 `hex_stripped`（无 #，它自己拼 `#`）。
2. **palette 文件不被 file_watcher 监听**：Noctalia v5 热载 = config reload → `onConfigReload()` → `resolveAndSet()` 读 palette，但 palette 文件本身不监听。matugen 写完后需 `noctalia msg config-reload` 触发重读。

## Why
Noctalia 的 palette JSON 格式约定（带 #）与 matugen 默认输出（hex_stripped 无 #）不同；Noctalia 热载只挂在 config 上，不挂 palette 文件。

## How to apply
- Noctalia palette 模板用 `hex`（带 #），caelestia 用 `hex_stripped`（无 #）——两个消费端格式相反
- 改 Noctalia palette 后必须 `noctalia msg config-reload`，否则不生效

相关: [[matugen-wallpaper-theming]] | wiki/desktop/noctalia.md
