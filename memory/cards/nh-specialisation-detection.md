---
id: nh-specialisation-detection
type: constraint
tags: [nh, specialisation, /etc/specialisation, activation, nixos-rebuild]
date: 2026-08-13
---

# nh 变体检测：/etc/specialisation 标记文件

## 问题

nh（`nh os switch`）需要知道「当前运行的是哪个 specialisation 变体」，才能切到正确变体的 activation 脚本（变体 toplevel 而非 base）。但 nh 没有 `--specialisation` 自动感知——它靠读一个非显而易见的运行时文件。

## 机制

nh 读 `/etc/specialisation`（`nh-nixos/src/nixos.rs:SPEC_LOCATION`）判断当前变体：
- 文件内容 = 变体名（如 `gnome`）→ nh 切到该变体的 toplevel
- 文件不存在 → nh 切到 base（main）
- 显式 `nh os switch -s <name>` 或 `-S`（忽略变体）可覆盖自动检测

## How to apply

- **每个 specialisation 变体必须在自己 configuration 里写** `environment.etc."specialisation".text = "<name>"`（本机 `specialisation/gnome/host.nix:21` 写 `gnome`）
- **main（base）不写**——写了一个不存在的 specialisation 名会让 nh 报错 "Specialisation does not exist"
- 这是 nh 的内部约定，非显而易见——**不要删这行**，删了 nh 就无法识别当前变体，`nh os switch` 会静默切回 base

## 相关

- [[gnome-specialisation]] — GNOME 变体的隔离架构，/etc/specialisation 标记是它的一部分
