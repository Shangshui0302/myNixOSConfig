{ config, lib, pkgs, ... }:

{
  # GNOME specialisation — 完整 GNOME 桌面（GDM Wayland 登录）。
  # 默认 boot 保持 kmscon + Hyprland/niri；开机在 systemd-boot 选 "NixOS (gnome)" 进 GNOME。
  # GDM 自动列出已装 wayland sessions（Hyprland / Hyprland (UWSM) / Niri / GNOME），可跨 DE 切换。
  specialisation.gnome.configuration = {
    services.desktopManager.gnome.enable = true;
    services.displayManager.gdm.enable = true;

    # GDM 接管 tty1。禁用 kmscon 避免边角问题（本机 kmscon 走 libseat=false raw-VT 特殊配置）。
    # base（greeter.nix）硬定义 enable=true，需 mkForce 覆盖。
    services.kmscon.enable = lib.mkForce false;

    # 全量 GNOME：core apps + 开发者工具全上；games 小游戏关闭。
    # core-apps 默认即 true；games / core-developer-tools 默认 false。
    # 注意：全量含 Epiphany → 拉入 webkitgtk 大包，首次构建/下载较慢。
    services.gnome.core-apps.enable = true;
    services.gnome.games.enable = false;
    services.gnome.core-developer-tools.enable = true;

    # kimpanel 扩展：让 fcitx5 候选窗显示在 GNOME Shell 之上（GNOME Wayland 已知限制）。
    # 装完需在 GNOME 里用 Extensions 应用手动启用（gnome.md 官方做法）。
    environment.systemPackages = [ pkgs.gnomeExtensions.kimpanel ];

    # ===== 用户设置持久化（从 dconf dump 提取）=====
    # 主题外观（gtk-theme/icon-theme/cursor/color-scheme）由 home/theme.nix + Noctalia 深色调度管理，不重复。
    # 壁纸用 yamadaryou（home.file 已复制到 ~/Pictures/Wallpapers/），比 dconf 里的时间戳路径稳定。
    services.desktopManager.gnome.favoriteAppsOverride = "['org.gnome.Nautilus.desktop']";
    services.desktopManager.gnome.extraGSettingsOverrides = ''
      [org.gnome.desktop.interface]
      show-battery-percentage=true
      clock-show-weekday=true

      [org.gnome.desktop.calendar]
      show-weekdate=true

      [org.gnome.desktop.datetime]
      automatic-timezone=true

      [org.gnome.desktop.peripherals.mouse]
      natural-scroll=false

      [org.gnome.desktop.peripherals.touchpad]
      click-method='fingers'
      edge-scrolling-enabled=false
      two-finger-scrolling-enabled=true

      [org.gnome.desktop.background]
      picture-uri='file:///home/lishangshui/Pictures/Wallpapers/yamadaryou.png'
      picture-options='zoom'

      [org.gnome.desktop.screensaver]
      picture-uri='file:///home/lishangshui/Pictures/Wallpapers/yamadaryou.png'
      picture-options='zoom'

      [org.gnome.settings-daemon.plugins.color]
      night-light-enabled=true
      night-light-schedule-automatic=false
      night-light-schedule-from=22.0

      [org.gnome.nautilus.preferences]
      default-folder-viewer='icon-view'
      date-time-format='detailed'
      show-create-link=true

      [org.gnome.nautilus.list-view]
      use-tree-view=true
    '';

    # fcitx5：GNOME Wayland 走 text-input-v3，官方建议不设 GTK_IM_MODULE
    # （GTK 应用用原生输入协议；Qt 走 QT_IM_MODULE，XWayland 走 XMODIFIERS）。
    # base（desktop.nix）的 GTK_IM_MODULE=fcitx 在此移除。
    environment.variables = {
      GTK_IM_MODULE = lib.mkForce null;
      QT_IM_MODULE = lib.mkForce "fcitx";
      XMODIFIERS = lib.mkForce "@im=fcitx";
    };
  };
}
