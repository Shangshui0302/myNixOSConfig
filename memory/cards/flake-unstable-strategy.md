---
id: flake-unstable-strategy
type: decision
tags: [flake, nixpkgs, stability]
date: 2026-08-05
---

# flake 全用 unstable，出问题再修

## 问题
调研过 stable+unstable 分拆策略（系统用 stable、个别包 pin unstable），发现对本机不现实——Hyprland 0.55 是 Lua 配置（`hyprland.lua`），走 stable 无法满足。权衡稳定性与维护成本。

## 决策
**全用 unstable**（nixos-unstable channel），出问题再修。

## Why
- stable+unstable 分拆对这套配置复杂度/收益不成比例，维护成本高
- 用户明确表态："我狂，我全用 unstable，出了问题再修"
- 本机是个人笔记本，非生产环境，出问题可即时修

## How to apply
- 不要为了某个包走 stable 单独 pin
- 涉及 overlay / unstable channel 的包，改动时说明原因
- 出问题时优先修配置，而非整体切换 channel
