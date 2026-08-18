---
id: hyprland-056-blur-amd
type: hardware
tags: [hyprland, amd, blur, gpu, 780M]
date: 2026-08-07
---

# Hyprland 0.56 blur 在 AMD 780M 上失效

## 问题

升级到 Hyprland 0.56 后，终端等透明窗口的背景模糊消失，只剩透明度。

## 根因

Hyprland 0.56 将 `decoration:blur:new_optimizations` 默认值从 `false` 改为 `true`。新的优化渲染路径在 AMD Radeon 780M (HawkPoint) 上导致透明窗口 blur 不生效。

## 决策

在 Hyprland Lua 配置中添加 `new_optimizations = false`，恢复旧的 blur 渲染路径。

## Why

`new_optimizations` 是性能优化，但在 AMD 780M 上有兼容性问题。关闭后视觉效果与 0.55 一致，性能损失轻微。

## How to apply

- 配置位置：`home/de/hyprland.nix` → `blur.new_optimizations = false`
- 后续 Hyprland 更新时，尝试移除此设置测试是否修复
- 相关：`home/de/hyprland.nix` L94-102
