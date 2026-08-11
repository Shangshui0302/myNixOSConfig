---
id: gnome-specialisation
type: decision
tags: [gnome, specialisation, gdm, desktop, kmscon]
date: 2026-08-11
---

# GNOME 用 specialisation 变体而非统一 GDM

## 决策

GNOME 作为 NixOS specialisation 变体（`host/gnome.nix`）：开机 systemd-boot 选 `NixOS (gnome)` 进 GDM + GNOME；main 保持 kmscon + Hyprland/niri 纯 TTY 工作流。

## Why

- 项目核心：纯 TTY 登录（kmscon + howdy 人脸解锁）。统一 GDM 会放弃该主流程
- greeter.nix 原注释即规划 "GNOME is isolated to a specialisation variant (with GDM)"
- specialisation 在 25.11/26.05 未废弃：`specialisation.<name>.configuration`，`inheritParentConfig` 默认 true（继承主配置），base 值需 `mkDefault` 才可被子变体覆盖
- GDM 自动列出 wayland-sessions（Hyprland/niri 模块自动注册 sessionPackages），GNOME 变体里可跨 DE 切换
- GDM 与 kmscon 当前 nixpkgs 已不硬冲突（GDM 开启时 kmscon 自动不占 tty1），但本机 kmscon 走 libseat=false raw-VT，变体里仍 `mkForce false` 禁用更稳

## How to apply

- `host/gnome.nix`：`services.desktopManager.gnome.enable` + `services.displayManager.gdm.enable` + `services.kmscon.enable = lib.mkForce false` + minimal GNOME（`core-apps.enable=false`、exclude gnome-tour/user-docs）+ 移除 `GTK_IM_MODULE`
- 共享同一 home-manager profile（GNOME 差异全在 NixOS 层，Noctalia/uwsm 在 GNOME 下 inert）
- 验证构建：`nix build .#nixosConfigurations.MechRevo-NixOS.config.specialisation.gnome.configuration.system.build.toplevel`
- 运行时切换：`nixos-rebuild switch --specialisation gnome`

相关: [[memory/cards/kmscon-tty-cjk-libseat]]
