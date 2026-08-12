---
title: GNOME
category: 桌面
tags: [gnome, gdm, specialisation, wayland]
updated: 2026-08-12
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

- **GNOME 应用**：`core-apps.enable = true`（core apps）+ `core-developer-tools.enable = true`（开发者工具）；`games.enable = false`（小游戏关闭）
- **排除 Epiphany**：`environment.gnome.excludePackages = [ pkgs.epiphany ]`（core-apps 默认含它，且拉入 webkitgtk 大包）
- **Shell 扩展**（`environment.systemPackages`，装完需在 Extensions 应用手动启用；`enabled-extensions` override 只影响新用户默认）：
  - 基础：kimpanel（fcitx5 候选窗）、dash-to-dock、blur-my-shell（毛玻璃）、vitals（监控）、user-themes（自定义 Shell 主题）、caffeine（顶栏咖啡杯，临时禁屏/禁睡眠）
  - 效率：clipboard-history（剪贴板历史）、extension-list、notification-timeout
  - 集成/锁屏：gsconnect（手机互通）、lockscreen-studio（锁屏美化）
  - 注：no-title-bar / pano 已被 nixpkgs 移除（上游停维护）；tray-icons-reloaded / forge / just-perfection / unite / hide-activities-button 未启用故移除（2026-08-12 清理）
- **dash-to-dock**：intellihide 全窗口避让（遮挡即隐藏、鼠标移边缘呼出）+ 底部 + DASHES 白条指示器，经 `extraGSettingsOverrides` 配置
- **主题**：`material-gnome-theme`（local-deriv 自建包，Material 3 风格），`user-theme name='Material-Gnome'` 加载；kimpanel 候选窗、顶栏等跟随
- **console**：`[org.gnome.Console]` 设 `shell=['fish']`（系统 passwd 默认是 bash）+ `ignore-scrollback-limit=true`
- **blur-my-shell**：静态高斯模糊 + 自带 corner pipeline（`pipeline_default_rounded`），panel/applications/dash-to-dock 分段配置，无需 rounded-blur 库
- **用户设置持久化**：`extraGSettingsOverrides`（状态栏/日历/外设/夜灯/nautilus/console 偏好 + dash-to-dock + blur-my-shell + user-theme + enabled-extensions）+ `favoriteAppsOverride`（Dock：Nautilus/Chrome/Console/Code）；壁纸指向 git 源 `assets/yamadaryou.png`。主题外观由 `home/theme.nix` + Noctalia 深色调度管理，不在此重复
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
