---
id: gnome-specialisation
type: decision
tags: [gnome, specialisation, gdm, desktop, kmscon, isolation]
date: 2026-08-12
---

# GNOME 用隔离 specialisation 变体（inheritParentConfig=false）

## 决策

GNOME 作为 `inheritParentConfig=false` 的 specialisation 变体（代码在独立的 `specialisation/gnome/`，与 `host/`、`home/` 平级）。开机 systemd-boot 选 `NixOS (gnome)` 进 GDM + GNOME；main 保持 kmscon + Hyprland/niri 纯 TTY 工作流。

## Why

- 主配置纯 TTY 登录（kmscon + howdy）；统一 GDM 会放弃该主流程
- **完全隔离**：`inheritParentConfig=true`（默认继承）会让 GNOME 闭包混入 Hyprland/foot/fcitx5 主题 addons/wlr portal/qt5ct；继承 + mkForce 反向关闭不彻底（foot-notify 的 hyprctl、xdg portal config、fcitx5 主题 addons 仍被继承，逐一 mkForce 易漏）。`inheritParentConfig=false` 用 `noUserModules.extendModules`（源码 `activation/specialisation.nix`）从零构建，GNOME 闭包天然不含 Hyprland 包体
- 变体不以代码片段存在：`specialisation/gnome/` 独立目录（default.nix/host.nix/home.nix），main 只留一行声明
- 共享 base：`host/base/` + `home/base.nix` 被 main 和变体共同 import（硬件/网络/服务/通用工具）；fcitx5 核心共享（GNOME 走 kimpanel、Hyprland 走 classicui），主题分层（main=adw-gtk3-dark，变体=Material-Gnome）
- GDM 与 kmscon 不硬冲突，但变体不 import `host/hyprland/greeter.nix`，kmscon 天然不存在，无需 mkForce

## How to apply

- `specialisation/gnome/default.nix`：变体入口，imports `../../hardware-configuration.nix` + `../../host/base/default.nix` + sops-nix/home-manager 模块 + overlays + `./host.nix`；`home-manager.users.lishangshui = import ./home.nix`（extraSpecialArgs 带 materialGnomeTheme）
- `specialisation/gnome/host.nix`：GDM + GNOME 分组 + 扩展 + material-gnome-theme + `extraGSettingsOverrides` + `favoriteAppsOverride`（无 kmscon/GTK_IM_MODULE 覆盖——变体根本不继承）
- `specialisation/gnome/home.nix`：import 共享 `../../home/base.nix` + Material-Gnome（gtk-theme + GTK4 链接 + `~/.themes` + flatpak override）
- main 声明在 `host/default.nix`：`specialisation.gnome = { inheritParentConfig = false; configuration = import ../specialisation/gnome/default.nix; }`
- 验证隔离：`nix eval .#nixosConfigurations.MechRevo-NixOS.config.specialisation.gnome.configuration.programs.hyprland.enable` 应为 false；闭包 grep 无 hyprland/foot/wlr/qt5ct/adw-gtk3/noctalia
- 运行时切换：`nixos-rebuild switch --flake . --specialisation gnome`

相关: [[memory/cards/kmscon-tty-cjk-libseat]]
