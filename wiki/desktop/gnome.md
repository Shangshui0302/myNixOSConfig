---
title: GNOME
category: 桌面
tags: [gnome, gdm, specialisation, wayland]
updated: 2026-08-11
---

# GNOME

## 定位

完整 GNOME 桌面，作为 **specialisation 变体**存在（`host/gnome.nix`）。默认 boot 保持 kmscon + Hyprland/niri 纯 TTY 工作流；想用 GNOME 时开机选 GNOME 变体，进 GDM 登录。

## 启动

1. 开机 boot 菜单选 `NixOS (gnome)`（当前代次的 GNOME 变体）
2. GDM Wayland 登录
3. GDM 登录屏可选 GNOME / Hyprland / Hyprland (UWSM) / Niri —— 已装 compositor 自动列出，GNOME 变体里也能跨 DE 切换

运行时切换（不重启系统）：
```bash
sudo nixos-rebuild switch --flake . --specialisation gnome
# 或
sudo /run/current-system/specialisation/gnome/bin/switch-to-configuration test
```

## 配置要点（host/gnome.nix）

- **全量 GNOME**：`services.gnome.core-apps.enable = true`（core apps）+ `services.gnome.games.enable = true`（游戏）+ `services.gnome.core-developer-tools.enable = true`（开发者工具）
- 注意全量含 Epiphany → 拉入 webkitgtk 大包，首次构建/下载较慢
- GDM 接管 tty1，GNOME 变体里 kmscon 禁用（本机 libseat=false raw-VT 特殊配置，避免边角问题）
- fcitx5：GNOME Wayland 走 text-input-v3，**不设 `GTK_IM_MODULE`**（GTK 用原生输入协议）；Qt 走 `QT_IM_MODULE`，XWayland 走 `XMODIFIERS`，均保留
- 共享同一 Home Manager profile——用户级配置（编辑器、主题、面板配置等）与主系统完全一致，无重复维护

## 故障排查

- GDM 登录屏缺 compositor 条目：`systemctl restart display-manager.service`
- fcitx5 候选窗不显示在 GNOME Shell UI 之上：GNOME 已知限制，需 kimpanel 扩展（官方 wiki 原话）
- 从 GNOME 变体回主系统：重启选默认 boot 条目即可（非 specialisation）

## 相关链接

- 决策原因：[GNOME 用 specialisation 变体](../../memory/cards/gnome-specialisation.md)
- 验证构建：`nix build .#nixosConfigurations.MechRevo-NixOS.config.specialisation.gnome.configuration.system.build.toplevel`
