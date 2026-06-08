# 深色模式架构

## 概览

本机深色模式由**两个独立调度器**协同工作，通过 hook 和 portal 桥接，实现手动切换和日出日落自动切换。

```
Noctalia ←──location调度──→ 太阳位置 (30.57/104.07 成都)
    │                              │
    │ darkModeChange hook          │ 独立调度
    ▼                              ▼
darkman ←──location调度──→ 太阳位置 (30.57/104.07 成都)
    │
    ├─ dconf ──→ GTK3 应用 (Nemo)
    ├─ qt5ct ──→ Qt5 应用 (WPS)
    └─ XDG Portal ──→ Firefox / Chrome / libadwaita
```

## 为什么两个调度器不打架

Noctalia 和 darkman 使用**相同的经纬度** (30.57/104.07)，计算出的日出日落时间一致。任何时候只会得到同一个结论（白天=亮色，晚上=暗色）。

- 谁先触发先执行，另一个随后触发时发现已是目标模式 → no-op
- 不需要做 "谁主谁从" 的选择，自然协同

## 关键原则

**不要在 `settings.json` 中硬编码 `darkMode` 初始值。**

```nix
# home/env/noctalia.nix → programs.noctalia-shell.settings.colorSchemes
colorSchemes = {
  useWallpaperColors = false;
  predefinedScheme = "yamadaryou";
  # 不设 darkMode！让调度器根据太阳位置决定
  schedulingMode = "location";
  manualSunrise = "06:30";
  manualSunset = "18:30";
  generationMethod = "monochrome";
  monitorForColors = "";
};
```

如果设了 `darkMode = false`，会在只读文件中形成一个固定锚点。调度器算出来该是暗色，文件说亮色，两者拉扯导致振荡。

同样，wallpaper 里的 `darkMode` 也要删：

```nix
# home/env/noctalia.nix → wallpaper.favorites
favorites = [
  {
    path = "...";
    colorScheme = "yamadaryou";
    # 不设 darkMode
    generationMethod = "monochrome";
    useWallpaperColors = false;
    paletteColors = [ ];
  }
];
```

## 配置文件

### Noctalia 调度 (`home/env/noctalia.nix`)

```nix
colorSchemes = {
  schedulingMode = "location";  # 基于经纬度自动计算日出日落
  predefinedScheme = "yamadaryou";
};
```

hook 在 darkMode 变化时通知 darkman：

```nix
hooks = {
  enabled = true;
  darkModeChange = ''
    if [ "$1" = "true" ]; then
      ${pkgs.darkman}/bin/darkman set dark
    else
      ${pkgs.darkman}/bin/darkman set light
    fi
  '';
  startup = "${pkgs.systemd}/bin/systemctl --user restart darkman";
  screenUnlock = "${pkgs.systemd}/bin/systemctl --user restart darkman";
};
```

- `darkModeChange`: Noctalia 切换时同步 darkman
- `startup`: 启动时确保 darkman 和当前 sun position 对齐
- `screenUnlock`: 解锁后重新对齐（休眠期间可能跨过日出日落）

### darkman 调度 (`home/theme.nix`)

```nix
services.darkman = {
  enable = true;
  settings = {
    lat = 30.57;
    lng = 104.07;
  };
  darkModeScripts.dconf = ''
    DCONF="${pkgs.dconf}/bin/dconf"
    $DCONF write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
    $DCONF write /org/gnome/desktop/interface/gtk-theme "'adw-gtk3-dark'"
    $DCONF write /org/gnome/desktop/interface/gtk-application-prefer-dark-theme "true"
  '';
  lightModeScripts.dconf = ''
    DCONF="${pkgs.dconf}/bin/dconf"
    $DCONF write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
    $DCONF write /org/gnome/desktop/interface/gtk-theme "'adw-gtk3'"
    $DCONF write /org/gnome/desktop/interface/gtk-application-prefer-dark-theme "false"
  '';
  darkModeScripts.qt5ct = ''
    mkdir -p ~/.config/qt5ct
    cat > ~/.config/qt5ct/qt5ct.conf << 'EOF'
    [Appearance]
    style=Fusion
    color_scheme=darker
    EOF
  '';
  lightModeScripts.qt5ct = ''
    mkdir -p ~/.config/qt5ct
    cat > ~/.config/qt5ct/qt5ct.conf << 'EOF'
    [Appearance]
    style=Fusion
    EOF
  '';
};
```

### XDG Portal 配置 (`host/desktop.nix`)

darkman 作为 portal 的 Settings 后端，应用通过 D-Bus 查询当前配色：

```nix
xdg.portal.config.hyprland = {
  default = [ "hyprland" "gtk" ];
  "org.freedesktop.impl.portal.Settings" = [ "darkman" ];
};
```

### dconf 默认值 (`home/theme.nix`)

```nix
dconf.settings = {
  "org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "adw-gtk3-dark";
    icon-theme = "Papirus";
    gtk-application-prefer-dark-theme = true;
  };
};
```

## 配色方案

Noctalia 使用 yamadaryou 配色方案，在 `home/env/noctalia.nix` 中定义：

```nix
# ~/.config/noctalia/colorschemes/yamadaryou/yamadaryou.json
# 包含 dark 和 light 两套终端颜色 + UI 颜色
```

Noctalia 切换模式时，模板系统重新渲染：
- **GTK CSS** → `~/.config/gtk-3.0/noctalia.css` 和 `~/.config/gtk-4.0/noctalia.css`
- **Hyprland 颜色** → `~/.config/hypr/noctalia-colors.lua`
- **Qt 颜色** → `~/.config/qt5ct/colors/noctalia.conf`
- **Telegram 主题** → `~/.config/telegram-desktop/themes/noctalia.tdesktop-theme`
- **Steam 主题** → `~/.steam/steam/steamui/skins/Material-Theme/css/main/colors/matugen.css`

## 调试命令

```bash
# 查看 darkman 当前模式
darkman get

# 手动切换 darkman
darkman set dark
darkman set light

# 查看 dconf 配色
dconf read /org/gnome/desktop/interface/color-scheme

# 查看 portal 配色 (1=dark, 2=light)
busctl --user call org.freedesktop.portal.Desktop \
  /org/freedesktop/portal/desktop \
  org.freedesktop.portal.Settings ReadOne ss \
  org.freedesktop.appearance color-scheme

# 查看 darkman 日志
journalctl --user -u darkman -f

# Noctalia IPC 切换
noctalia-shell ipc call darkMode setDark
noctalia-shell ipc call darkMode setLight
```

## 注意事项

- `settings.json` 是只读 nix store symlink，Noctalia 运行时修改只存于内存
- 不要手动修改 `~/.config/noctalia/settings.json`
- `screenUnlock` hook 会重启 darkman，解锁后可能触发模式切换（如果跨了日出日落）
- Chrome 可能需要重启才能跟随 portal 变化（v148 已知问题）
- Firefox 动态跟随 portal，无需重启
