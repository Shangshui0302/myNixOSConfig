---
title: 深色模式架构
category: desktop
tags: [darkmode, noctalia, dconf, qt5ct, portal]
updated: 2026-08-06
---

# 深色模式架构

## 概览

Noctalia 是唯一调度器，基于经纬度自动计算日出日落。hook 直接写 dconf 和 qt5ct，xdg-desktop-portal-gtk 读取 gsettings 并暴露 Settings portal，应用通过 portal 查询当前配色。

```
Noctalia (唯一调度器, 30.57/104.07)
  │
  │ darkModeChange hook
  ├─ dconf color-scheme ──→ GTK3/GTK4 应用
  ├─ qt5ct ──→ Qt5 应用 (WPS)
  └─→ gsettings ←── portal-gtk 读取 ──→ XDG Portal ──→ Chrome/Firefox/WebKitGTK
```

## 为什么不需要 darkman

之前 darkman 的角色被拆成了两块，各自由已有的组件承担：

| 原来 darkman | 现在 |
|-------------|------|
| 日出日落调度 | Noctalia（本就支持 location scheduling） |
| 写 dconf/qt5ct | Noctalia darkModeChange hook |
| 暴露 XDG Settings portal | xdg-desktop-portal-gtk |

砍掉 darkman 后少了一个常驻进程，架构更简单，app 跟随率反而更高（portal-gtk 比 darkman 实现了更多 portal 接口）。

## 关键原则

**不要在 `settings.json` 中硬编码 `darkMode` 初始值。**

```nix
# home/env/noctalia.nix → programs.noctalia-shell.settings.colorSchemes
colorSchemes = {
  schedulingMode = "location";    # Noctalia 根据日出日落自动决定
  predefinedScheme = "yamadaryou";
  # 不设 darkMode！
};
```

如果设了 `darkMode = false`，会在只读文件中形成一个固定锚点。调度器算出来该是暗色，文件说亮色，两者拉扯导致振荡。

## 配置文件

### Noctalia 调度 + hook (`home/env/noctalia.nix`)

```nix
colorSchemes = {
  schedulingMode = "location";  # 经纬度 30.57/104.07，自动计算日出日落
  predefinedScheme = "yamadaryou";
};

hooks = {
  enabled = true;
  darkModeChange = <script>;  # 写 dconf color-scheme + qt5ct
};
```

hook 直接写入 dconf 和 qt5ct，不再经过 darkman 中转。

### XDG Portal (`host/desktop.nix`)

portal-gtk 从 gsettings 读取 color-scheme，暴露给所有 portal-aware 应用：

```nix
xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
xdg.portal.config.hyprland = {
  default = [ "hyprland" "gtk" ];
  "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
};
```

### dconf 默认值 (`home/theme.nix`)

```nix
dconf.settings = {
  "org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "adw-gtk3-dark";
  };
};
```

## 调试命令

```bash
# 查看 dconf 配色
dconf read /org/gnome/desktop/interface/color-scheme

# 查看 portal 配色 (0=跟随default, 1=dark, 2=light)
busctl --user call org.freedesktop.portal.Desktop \
  /org/freedesktop/portal/desktop \
  org.freedesktop.portal.Settings ReadOne ss \
  org.freedesktop.appearance color-scheme

# Noctalia 手动切换
noctalia-shell ipc call darkMode setDark
noctalia-shell ipc call darkMode setLight

# portal-gtk 状态
systemctl --user status xdg-desktop-portal-gtk
```

## 注意事项

- `settings.json` 是只读 nix store symlink，Noctalia 运行时修改只存于内存
- 不要手动修改 `~/.config/noctalia/settings.json`
- Chrome 可能需要重启才能跟随 portal 变化
- Firefox 动态跟随 portal，无需重启

## 相关链接

- [Noctalia](noctalia.md) — 深色模式调度器，hook 写 dconf/qt5ct
- [Hyprland](hyprland.md) — 边框颜色跟随 Noctalia 配色方案
- [wiki 首页](../README.md)
