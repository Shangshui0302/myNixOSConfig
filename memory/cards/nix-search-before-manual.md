---
id: nix-search-before-manual
type: constraint
tags: [nix, workflow, search]
date: 2026-08-05
---

# 查包强制多路径搜索，禁止一次查不到就手搓

## 问题
两次手搓经历的教训：先手搓 onedrive systemd service 但 `programs.onedrive` 模块存在；后手搓 yazi `xdg.configFile` 但 `programs.yazi` 模块存在。每次都是查了但试得不够多就放弃了。

## 决策
使用 Nix 管理系统时，**强制**先尝试多种方式查包/查 module，禁止一次查不到就手搓：

1. `nix eval` 换路径：`services.*` → `programs.*` → `systemd.user.*`
2. 搜 HM/NixOS 源码树：`find <source> -name "*.nix" | xargs grep -l "<keyword>"`
3. MyNixOS 在线文档：https://mynixos.com

## Why
nix eval 没结果不代表 module 不存在。Nix 没有模糊搜索，一次查不到就手搓会造出与官方模块重复/冲突的配置。

## How to apply
每次在 Nix 里实现功能前，先尝试至少 2-3 种搜索方式，换路径、搜源码树、查 MyNixOS 文档，确认官方模块确实不存在后才手搓。
