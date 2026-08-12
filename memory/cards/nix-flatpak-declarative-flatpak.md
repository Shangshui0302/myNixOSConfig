---
id: nix-flatpak-declarative-flatpak
type: decision
tags: [flatpak, nix-flatpak, declarative, home-manager]
date: 2026-08-12
---

# Flatpak 声明式管理：nix-flatpak home-manager 模块

## 现状

本机 flatpak 应用由 nix-flatpak 的 **home-manager 模块**声明式管理（用户级 flatpak，装到 `~/.local/share/flatpak`）：

- `home/default.nix` import `inputs.nix-flatpak.homeManagerModules.nix-flatpak`
- `home/productivity/comms.nix`：`services.flatpak.packages = [ "com.tencent.WeChat" ]` + `services.flatpak.overrides`（WeChat 文件系统权限，如 `~/Downloads:rw`）
- `home/env/systools.nix`：`services.flatpak.packages = [ "io.github.wh201906.serialtest" ]`
- `host/gaming.nix`：`services.flatpak.enable = true`（NixOS 原生 flatpak 引擎，是 nix-flatpak 的前提）

## Why

声明式 flatpak 进 git、可重现、换机 `nixos-rebuild` 自动恢复。nix-flatpak 是 convergent mode——声明之外手动装的 flatpak 不会被删。home-manager 版 = 用户级；另有 NixOS 版（`nixosModules.nix-flatpak`）= 系统级（`/var/lib/flatpak`），单用户桌面用 home-manager 版即可。

## How to apply

- 加 flatpak 应用：在对应 `home/*.nix` 的 `services.flatpak.packages` 追加 app id
- 改应用权限：`services.flatpak.overrides."<app-id>"`（`Context.filesystems` 等字段）
- **别误判「没在用 nix-flatpak」**——它早已在 `home/default.nix` 启用。曾在对话中因只查 flake.nix/host/ 漏看 home/ 而误判，教训是查配置要覆盖 home 目录

相关: [[memory/cards/ai-tools-source]]
