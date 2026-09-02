---
title: GNOME
category: 桌面
tags: [gnome, gdm, specialisation, wayland]
updated: 2026-09-02
---

# GNOME

## 定位

完整 GNOME 桌面，作为 **`inheritParentConfig=false` 的 specialisation 变体**存在（代码在独立的 `specialisation/gnome/` 目录，不继承 main 的 Hyprland 配置——Hyprland/foot/fcitx5 主题等包体完全不进 GNOME 闭包）。默认 boot 使用 greetd + tuigreet 启动 Hyprland/niri；想用 GNOME 时开机选 GNOME 变体，进 GDM 登录。

## 启动

1. 开机 boot 菜单选 `NixOS (gnome)`（当前代次的 GNOME 变体）
2. GDM Wayland 登录
3. GDM 登录屏默认 GNOME session（变体隔离后不含 Hyprland/niri compositor）

运行时切换（不重启系统）：
```bash
sudo nixos-rebuild switch --flake . --specialisation gnome
# 或
sudo /run/current-system/specialisation/gnome/bin/switch-to-configuration test
```

## 配置要点（specialisation/gnome/）

- **隔离机制**：`inheritParentConfig=false`，变体从零 import 共享 `host/base/` + GNOME 专属（`host.nix`）+ 变体 home（`home.nix`，import 共享 `home/base.nix` + Material 主题）。Hyprland 闭包不含 material-gnome-theme，GNOME 闭包不含 Hyprland/foot/wlr portal/qt5ct/adw-gtk3/noctalia
- **GSettings override 生效条件**（gnome.md 官方）：override 某包 schema 必须把该包加进 `extraGSettingsOverridePackages`，否则对应段被编译丢弃（Console/nautilus 曾因此失效）。GNOME Shell 扩展 schema 在非标准路径（`share/gnome-shell/extensions/<uuid>/schemas/`），需用 `withStandardSchemas` 链接到标准 gsettings-schemas 路径后加入 override 包，dash-to-dock/blur-my-shell/user-theme 的 override 才生效

- **GNOME 应用**：`core-apps.enable = true`（core apps）+ `core-developer-tools.enable = true`（开发者工具）；`games.enable = false`（小游戏关闭）
- **排除 Epiphany**：`environment.gnome.excludePackages = [ pkgs.epiphany ]`（core-apps 默认含它，且拉入 webkitgtk 大包）
- **Shell 扩展**（`environment.systemPackages`，装完需在 Extensions 应用手动启用；`enabled-extensions` override 只影响新用户默认）：
  - 基础：kimpanel（fcitx5 候选窗）、dash-to-dock、blur-my-shell（毛玻璃）、vitals（监控）、user-themes（自定义 Shell 主题）、caffeine（顶栏咖啡杯，临时禁屏/禁睡眠）
  - 效率：clipboard-history（剪贴板历史）、extension-list、notification-timeout
  - 集成/锁屏：gsconnect（手机互通）、lockscreen-studio（锁屏美化）
  - 注：no-title-bar / pano 已被 nixpkgs 移除（上游停维护）；tray-icons-reloaded / forge / just-perfection / unite / hide-activities-button 未启用故移除（2026-08-12 清理）
- **dash-to-dock**：intellihide 全窗口避让（遮挡即隐藏、鼠标移边缘呼出）+ 底部 + DASHES 白条指示器，经 `extraGSettingsOverrides` 配置
- **主题**：`material-gnome-theme`（local-deriv 自建包：构建期 matugen 从壁纸取色 + shellLayout 布局参数化），`user-theme name='Material-Gnome'` 加载；GTK4 链接 + `~/.themes` + flatpak override 限定 GNOME 变体（Hyprland 主桌面保持 adw-gtk3-dark）
- **console**：`[org.gnome.Console]` 设 `shell=['fish']`（系统 passwd 默认是 bash）+ `ignore-scrollback-limit=true`
- **blur-my-shell**：静态高斯模糊 + 自带 corner pipeline（`pipeline_default_rounded`），panel/applications/dash-to-dock 分段配置，无需 rounded-blur 库
- **用户设置持久化**：`extraGSettingsOverrides`（状态栏/日历/外设/夜灯/nautilus/console 偏好 + dash-to-dock + blur-my-shell + user-theme + enabled-extensions）+ `favoriteAppsOverride`（Dock：Nautilus/Chrome/Console/Code）；默认壁纸使用 `assets/nixos_logo.png`。图标/深浅色由 `home/theme-base.nix` 共享，gtk-theme 在变体 `home.nix` 设 Material-Gnome
- GDM 接管 tty1；变体不 import `host/de/greeter.nix`（greetd/kmscon 天然不存在，无需覆盖）
- fcitx5：核心在共享 `host/base/desktop.nix`；GNOME Wayland 走 text-input-v3，**无 `GTK_IM_MODULE`**（base 只设 QT_IM_MODULE/XMODIFIERS）；kimpanel addon 强制启用
- 变体 home = 共享 `home/base.nix`（通用工具）+ Material 主题；Hyprland 主桌面 home 另行 `home/de.nix`，两套互不干扰

## 故障排查

- GDM 登录屏缺 compositor 条目：`systemctl restart display-manager.service`
- fcitx5 候选窗不显示在 GNOME Shell UI 之上：GNOME 已知限制，需 kimpanel 扩展（官方 wiki 原话）
- 从 GNOME 变体回主系统：重启选默认 boot 条目即可（非 specialisation）

## 相关链接

- 决策原因：[GNOME 用 specialisation 变体](../../memory/cards/gnome-specialisation.md)
- 验证构建：`nix build .#nixosConfigurations.MechRevo-NixOS.config.specialisation.gnome.configuration.system.build.toplevel`
