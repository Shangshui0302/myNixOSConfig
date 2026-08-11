---
id: mechrevo-psr-snow-artifacts
type: hardware
tags: [mechrevo, amd, 780M, psr, replay, niri, cosmic, display, kernel]
date: 2026-08-11
---

# niri/cosmic 局部雪花点闪烁 — PSR/Panel Replay 固件 bug

## 问题

niri 和 cosmic（Smithay 系）中，滚动/动画/移动窗口时屏幕局部出现雪花点闪烁。Hyprland（wlroots 系）没有此现象。**录屏/截图看不到雪花**（只在面板上可见）。

## 根因

amd Display Core（DCN 3.14 / 780M）的 DMCUB 固件在 PSR/Panel Replay **选择性更新**模式下给局部矩形组装了损坏像素数据（drm/amd#5087，影响 Framework 16 / Lenovo T14 / HONOR MagicBook 等）。录屏不可见 → 伪影发生在 framebuffer 之后、面板之前（固件层），不是合成器渲染层。niri 动画产生密集局部 damage，恰好触发选择性更新路径；Hyprland 提交模式不触发（Fedora 用户同机验证：仅 niri 复现，Hyprland/GNOME 无）。

## 尝试与结果

尝试 `dcdebugmask` 叠加 PSR/Replay 禁用位（`0x40000` → `0x40410`，即 +0x10 +0x400），**实测未消除雪花**。PSR-SU 位（0x200）未试。`host/boot.nix` 已回退为 `0x40000`（仅亮度曲线 fix）。

## 现状

回落 Hyprland 主力，niri 保留偶尔使用。雪花不影响核心功能，公认可"忍"的 AMD 780M 已知 bug。待 AMD 上游 patch（drm/amd#5087，DCN 3.14 强制全帧刷新）mainline 后重新测试。

## Why（排查思路留存）

- 雪花只在录屏外可见 → 锁定固件层而非合成器层
- Fedora 用户同机同 GPU 验证仅 niri 复现、Hyprland/GNOME 无 → 合成器接入模式影响触发频率
- `dcdebugmask` 仅禁 PSR/Replay 电源管理位，未触及 PSR-SU 部分刷新逻辑——可能正是 SU 路径导致

相关: [[memory/cards/mechrevo-amd-backlight-curve]] | [[memory/cards/amd-kernel-stay-lts]]
