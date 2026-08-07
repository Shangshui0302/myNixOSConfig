---
id: amd-kernel-stay-lts
type: decision
tags: [amd, kernel, nixpkgs, 780M, rdna]
date: 2026-08-07
---

# AMD 核显：留在 nixpkgs 默认内核，不上 linuxPackages_latest

## 问题

内核 mainline 已到 7.1.x，系统跑的却是 6.18.42，是否该升级？（起因是想靠新内核修背光曲线 bug。）

## 决策

维持 nixpkgs 默认内核 `linuxPackages`（当前 6.18.42，LTS），**不**设 `boot.kernelPackages = pkgs.linuxPackages_latest`（7.1.6），也不为单个 bug 去升级。

## Why

- nixpkgs 默认内核故意滞后 mainline，选保守 LTS 图稳定 + 驱动兼容广；`linuxPackages_latest` 才是新内核。
- 6.18/6.19/7.x 的 amdgpu 有 **RDNA3/4 重负载硬挂起**回归（Phoronix/Framework 确认，未 bisect，整机死机且日志来不及落盘）。本机 780M 属 RDNA3，直接受影响面。
- 7.x 的主要新特性对本机无收益：XFS/EXT4 改进（本机用 Btrfs）、Arm 平台改进（本机 x86_64）、Rust/Clang 构建基建（用户无感）。
- 背光 bug 已由 `dcdebugmask` 与内核版本解耦解决，升级动机不成立。

## How to apply

- 不在 `host/boot.nix` 设 `boot.kernelPackages`，即用默认。
- 若将来必须换内核（新硬件/明确特性需求），优先选 LTS 而非 latest，并先在 feature 分支验证 GPU 重负载稳定性。
- 判断"内核是否过时"看 nixpkgs 默认给什么，而非 mainline 版本号。

相关: [[memory/cards/mechrevo-amd-backlight-curve]] | [[memory/cards/flake-unstable-strategy]]
