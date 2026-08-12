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
    services.gnome.core-apps.enable = true;
    services.gnome.games.enable = false;
    services.gnome.core-developer-tools.enable = true;

    # 排除 Epiphany（GNOME 自带浏览器）：core-apps 默认含它，且拉入 webkitgtk 大包。
    # environment.gnome.excludePackages 从所有 gnome 分组 systemPackages 里按包名剔除。
    environment.gnome.excludePackages = [ pkgs.epiphany ];

    # GNOME Shell 扩展。装完需在 GNOME 的 Extensions 应用手动启用一次（gnome.md 官方做法）。
    # 基础：kimpanel（fcitx5 候选窗）、dash-to-dock（intellihide 避让 dock）、tray-icons-reloaded（托盘）、
    #       blur-my-shell（毛玻璃）、vitals（监控）、just-perfection（微调）。
    # 平铺/窗口：forge（快捷键平铺）、unite（顶栏整合）。
    # 效率：clipboard-history（剪贴板历史，替代 clipboard-indicator）、extension-list（顶栏扩展管理）、
    #       notification-timeout（通知时长）、hide-activities-button（隐藏 Activities 按钮，配合 dock）。
    # 集成：gsconnect（手机互通）。锁屏：lockscreen-studio（锁屏自定义美化）。
    # 注：no-title-bar / pano 已被 nixpkgs 移除（上游停维护），故未收录。
    environment.systemPackages = [
      pkgs.gnomeExtensions.kimpanel
      pkgs.gnomeExtensions.dash-to-dock
      pkgs.gnomeExtensions.tray-icons-reloaded
      pkgs.gnomeExtensions.blur-my-shell
      pkgs.gnomeExtensions.vitals
      pkgs.gnomeExtensions.just-perfection
      pkgs.gnomeExtensions.forge
      pkgs.gnomeExtensions.unite
      pkgs.gnomeExtensions.gsconnect
      pkgs.gnomeExtensions.clipboard-history
      pkgs.gnomeExtensions.extension-list
      pkgs.gnomeExtensions.notification-timeout
      pkgs.gnomeExtensions.hide-activities-button
      pkgs.gnomeExtensions.lockscreen-studio
    ];

    # ===== 用户设置持久化（从 dconf dump 提取）=====
    # 主题外观（gtk-theme/icon-theme/cursor/color-scheme）由 home/theme.nix + Noctalia 深色调度管理，不重复。
    # 壁纸直接指向 git 源文件 assets/yamadaryou.png（版本管理内，随仓库可重现）。
    services.desktopManager.gnome.favoriteAppsOverride = "['org.gnome.Nautilus.desktop', 'google-chrome.desktop', 'org.gnome.Console.desktop', 'code.desktop']";
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
      picture-uri='file:///home/lishangshui/myNixOSConfig/assets/yamadaryou.png'
      picture-options='zoom'

      [org.gnome.desktop.screensaver]
      picture-uri='file:///home/lishangshui/myNixOSConfig/assets/yamadaryou.png'
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

      [org.gnome.Console]
      ignore-scrollback-limit=true

      # Dash to Dock：intellihide 全窗口避让（遮挡即隐藏，鼠标移到边缘呼出）+ 底部 + DASHES 白条。
      # 键值对照 dash-to-dock schema 源码（micheleg/dash-to-dock 仓库）确认。
      [org.gnome.shell.extensions.dash-to-dock]
      dock-fixed=false
      intellihide=true
      intellihide-mode='ALL_WINDOWS'
      dock-position='BOTTOM'
      show-running=true
      running-indicator-style='DASHES'

      # 新用户默认启用扩展；已有用户 dconf 值优先，需手动启用一次。
      [org.gnome.shell]
      enabled-extensions=[ 'kimpanel@kde.org', 'dash-to-dock@micxgx.gmail.com', 'trayIconsReloaded@selfmade.pl', 'blur-my-shell@aunetx', 'Vitals@CoreCoding.com', 'just-perfection-desktop@just-perfection', 'forge@jmmaranan.com', 'unite@hardpixel.eu', 'gsconnect@andyholmes.github.io', 'clipboard-history@alexsaveau.dev', 'extension-list@tu.berry', 'notification-timeout@chlumskyvaclav.gmail.com', 'Hide_Activities@shay.shayel.org', 'lockscreen-studio@pedro.projects' ]
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
