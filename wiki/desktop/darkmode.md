---
title: 深色模式与动态配色
category: desktop
tags: [darkmode, darkman, matugen, gtk, qt, portal]
updated: 2026-09-06
---

# 深色模式与动态配色

主桌面由 **Darkman** 保存唯一的深浅色状态；它同时提供 XDG Settings portal，并按成都坐标的日出日落自动调度。Mihomo 不参与定位：Darkman 使用固定坐标，不读取代理出口 IP。

```
darkman set/toggle
  ├─ XDG Settings portal → GTK4 双配色媒体查询、Firefox、浏览器、portal-aware 应用
  └─ theme-apply
      ├─ Matugen → GTK4 双配色、GTK3 双主题、Qt/Kvantum、Dolphin、Noctalia、Caelestia、Hyprland/niri
      ├─ dconf color-scheme + GTK3 当前主题名
      ├─ Fcitx5 深浅主题 + Matugen 重点色 + 每次成功渲染后重启 Fcitx5
      └─ Noctalia 当前模式
```

## 切换模式

| 操作 | 命令/快捷键 |
|------|-------------|
| 切换深浅色 | `darkman toggle` 或 `Super + Shift + D` |
| 强制深色 | `darkman set dark` |
| 强制浅色 | `darkman set light` |
| 查看当前模式 | `darkman get` |

Darkman 自带“Toggle darkman”桌面入口，可从任意启动器调用。Noctalia 不再提供 DarkMode 开关；它只显示并跟随 Darkman 已选择的模式。

## 自动调度

Darkman 使用成都的固定坐标计算日出和日落：

```text
latitude:  30.57
longitude: 104.07
```

因此自动切换不依赖 Geoclue、Wi-Fi 定位或外部 IP 定位，也不会因为 Mihomo 的代理节点在其他地区而误判位置。需要临时手动切换时仍可使用 `darkman set dark|light`；下一次日出或日落会恢复自动节奏。

检查 Darkman 是否已按当前配置运行：

```bash
darkman check
journalctl --user -u darkman -b
```

## GTK 与 Qt

- **GTK4**：`Material-Gnome-Matugen/gtk-4.0/colors.css` 始终同时包含浅色和深色变量，用 `@media (prefers-color-scheme: dark)` 选择。GTK4 收到 portal 模式事件时不再依赖 Matugen 写文件的先后顺序，因此不会读取上一轮颜色而反向。
- **GTK3**：同时维护 `Material-Gnome-Matugen` 和 `Material-Gnome-Matugen-Dark` 两个完整主题。Matugen 先渲染两套颜色，再由 `theme-apply` 写入当前 `gtk-theme`。
- **Flatpak GTK 应用**：继续通过 `$HOME/.themes:ro` 和固定 `GTK_THEME=Material-Gnome-Matugen` 读取主题。GTK4 4.20 及以上可使用双配色媒体查询；GTK3 Flatpak 暂不动态切换到 `-Dark` 目录。
- **Qt5/Qt6**：Home Manager 的 `qtct` 同时管理两代平台插件，控件样式统一为 Kvantum；`MaterialAdw` 的 `kvconfig`/SVG 由 Matugen 写入 `~/.config/Kvantum/MaterialAdw/`，两代 `qtct` 分别读取 `~/.config/qt5ct/colors/matugen.conf` 与 `~/.config/qt6ct/colors/matugen.conf`。Qt 应用通常只在启动时读取调色板，切壁纸后重新打开即可。
- **Dolphin/KDE**：Matugen 另外生成 `~/.local/share/color-schemes/MaterialAdwMatugen.colors`，并将 `~/.config/dolphinrc` 的 `[UiSettings] ColorScheme` 指向 `MaterialAdwMatugen`。这样文件视图、选中态等 KDE 语义色与 Kvantum 控件保持同一套 M3 色板。
- **Foot**：继续由 Stylix 管理，不随壁纸变化。
- **Fcitx5**：系统级 ClassicUI 配置是回退值；[`fcitx5-mellow-themes-matugen`](https://github.com/Shangshui0302/fcitx5-mellow-themes-matugen) 提供两套 Mellow 静态资源，`theme-apply` 为用户目录生成两套完整 `theme.conf` 和 `highlight.svg`。完整配置避免用户层颜色片段遮蔽 Nix profile 中的布局；模式切换或壁纸取色成功后都会重启 Fcitx5。

部分拥有自绘主题的应用可能忽略系统 GTK/Qt 调色板，这是应用本身的限制。

## 常用检查

```bash
# 当前 Darkman 状态、深色偏好与 portal 返回值
darkman get
dconf read /org/gnome/desktop/interface/color-scheme
busctl --user call org.freedesktop.portal.Desktop \
  /org/freedesktop/portal/desktop \
  org.freedesktop.portal.Settings ReadOne ss \
  org.freedesktop.appearance color-scheme

# 最近一次壁纸取色产物
stat ~/.themes/Material-Gnome-Matugen/gtk-3.0/colors.css \
  ~/.themes/Material-Gnome-Matugen-Dark/gtk-3.0/colors.css \
  ~/.themes/Material-Gnome-Matugen/gtk-4.0/colors.css \
  ~/.config/qt5ct/colors/matugen.conf \
  ~/.config/qt6ct/colors/matugen.conf \
  ~/.config/Kvantum/MaterialAdw/MaterialAdw.kvconfig \
  ~/.config/Kvantum/MaterialAdw/MaterialAdw.svg \
  ~/.local/share/color-schemes/MaterialAdwMatugen.colors \
  ~/.local/share/fcitx5/themes/mellow-matugen/theme.conf \
  ~/.local/share/fcitx5/themes/mellow-matugen-dark/theme.conf \
  ~/.local/share/fcitx5/themes/mellow-matugen/highlight.svg \
  ~/.local/share/fcitx5/themes/mellow-matugen-dark/highlight.svg

# 两套 Fcitx5 配置都必须是完整主题，不能只有颜色字段
grep -nE '^\[Metadata\]|^\[InputPanel/Background\]|^Image=panel\.svg$' \
  ~/.local/share/fcitx5/themes/mellow-matugen{,-dark}/theme.conf

# GTK4 产物应包含运行时深色分支
grep -n 'prefers-color-scheme: dark' \
  ~/.themes/Material-Gnome-Matugen/gtk-4.0/colors.css

# Dolphin 应使用 Matugen 生成的 KDE 语义色方案
awk '/^\[UiSettings\]/{in_ui=1; next} /^\[/{in_ui=0} in_ui && /^ColorScheme=/{print}' \
  ~/.config/dolphinrc
```

宿主 GTK4 应用应在模式切换时立即跟随；GTK3 是否实时刷新取决于应用是否监听主题名变化。切壁纸会更新 Fcitx5 重点色并重启输入法，但不保证其他已运行 GTK 应用热载颜色文件；应等旧进程退出后重新打开。Qt 应用同样通常需要重新打开。portal 查询失败时，先检查：

```bash
systemctl --user status darkman xdg-desktop-portal
journalctl --user -u darkman -b
```

若自动切换时间明显不对，确认当前运行的配置包含成都坐标，并检查系统时区；不要根据 Mihomo 当前节点判断 Darkman 的位置。若 portal 后端无法启动，先执行 `systemctl --user restart darkman xdg-desktop-portal`。GTK 的文件选择器仍由 gtk portal 提供；若它单独报 `not-found`，再排查历史遗留的 `xdg-desktop-portal-gtk.service` dangling symlink。

## 相关链接

- [Hyprland](hyprland.md) — 壁纸切换与合成器边框
- [Noctalia](noctalia.md) — 面板 palette
- [Fcitx5](fcitx5.md) — 候选窗深浅主题
- [Darkman 主题状态决策卡](../../memory/cards/darkman-theme-authority.md)
- [portal-gtk 故障决策卡](../../memory/cards/portal-gtk-dangling-symlink.md)
- [Matugen 动态取色决策卡](../../memory/cards/matugen-wallpaper-theming.md)
