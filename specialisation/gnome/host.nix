{ config, lib, pkgs, materialGnomeTheme, ... }:

let
  # 扩展 schema 在 share/gnome-shell/extensions/<uuid>/schemas/（非标准路径），
  # nixos-gsettings-overrides 编译时不包含 → [org.gnome.shell.extensions.*] 的 override 段被丢弃。
  # 把 schema 链接到标准 gsettings-schemas 路径，扩展 schema 才进入 override 包，override 才生效。
  withStandardSchemas = ext: ext.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      mkdir -p $out/share/gsettings-schemas/${ext.name}/glib-2.0/schemas
      cp -r $out/share/gnome-shell/extensions/*/schemas/*.gschema.xml \
        $out/share/gsettings-schemas/${ext.name}/glib-2.0/schemas/ 2>/dev/null || true
    '';
  });
in
{
  # GNOME 变体系统层（inheritParentConfig=false，不继承 main 的 Hyprland/foot/fcitx5 主题配置）。
  # fcitx5 核心 + QT_IM_MODULE/XMODIFIERS 来自 host/base/desktop.nix；GTK_IM_MODULE 未设置（GNOME 原生 text-input-v3）。

  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  # 全量 GNOME：core apps + 开发者工具全上；games 小游戏关闭。
  services.gnome.core-apps.enable = true;
  services.gnome.games.enable = false;
  services.gnome.core-developer-tools.enable = true;

  # 排除 Epiphany（GNOME 自带浏览器）：core-apps 默认含它，且拉入 webkitgtk 大包。
  environment.gnome.excludePackages = [ pkgs.epiphany ];

  # GNOME Shell 扩展。装完需在 GNOME 的 Extensions 应用手动启用一次（gnome.md 官方做法）。
  # 基础：kimpanel（fcitx5 候选窗）、dash-to-dock（intellihide 避让 dock）、blur-my-shell（毛玻璃）、
  #       vitals（监控）、user-themes（加载自定义 Shell 主题）、caffeine（顶栏咖啡杯，临时禁屏/禁睡眠）。
  # 效率：clipboard-history（剪贴板历史）、extension-list（顶栏扩展管理）、notification-timeout（通知时长）。
  # 集成/锁屏：gsconnect（手机互通）、lockscreen-studio（锁屏美化）。
  # 主题：material-gnome-theme（local-deriv，Material 3 风格，见下方 user-theme override）。
  # 注：no-title-bar / pano 已被 nixpkgs 移除（上游停维护）；
  #     tray-icons-reloaded / forge / just-perfection / unite / hide-activities-button 未启用故移除（2026-08-12 清理）。
  environment.systemPackages = [
    pkgs.gnomeExtensions.kimpanel
    pkgs.gnomeExtensions.dash-to-dock
    pkgs.gnomeExtensions.blur-my-shell
    pkgs.gnomeExtensions.vitals
    pkgs.gnomeExtensions.user-themes
    pkgs.gnomeExtensions.caffeine
    pkgs.gnomeExtensions.gsconnect
    pkgs.gnomeExtensions.clipboard-history
    pkgs.gnomeExtensions.extension-list
    pkgs.gnomeExtensions.notification-timeout
    pkgs.gnomeExtensions.lockscreen-studio
    materialGnomeTheme # flake 共享包（参数在 flake.nix 集中定义：壁纸取色 + 布局）
  ];

  # ===== 用户设置持久化（从 dconf dump 提取）=====
  # 主题外观（gtk-theme/icon-theme/cursor/color-scheme）：gtk-theme 在 home.nix（Material-Gnome），
  # 图标/深浅色由 home/base.nix 共享；壁纸指向 git 源文件 assets/yamadaryou.png。
  # 官方文档（gnome.md）：override 某包 schema 必须把该包加进 extraGSettingsOverridePackages，
  # 否则对应段 override 不生效（gschema 编译时丢弃未知段）。
  # 注意：只能加标准 gsettings-schemas 路径的包；GNOME Shell 扩展的 schema 在
  # share/gnome-shell/extensions/<uuid>/schemas/（非标准路径），加进来会让 overrides 构建 cp 失败。
  # 扩展的 override（dash-to-dock/blur-my-shell/user-theme）靠 GNOME 会话 XDG_DATA_DIRS 暴露 schema 生效。
  services.desktopManager.gnome.extraGSettingsOverridePackages = [
    pkgs.gnome-console
    pkgs.nautilus
    (withStandardSchemas pkgs.gnomeExtensions.dash-to-dock)
    (withStandardSchemas pkgs.gnomeExtensions.user-themes)
  ];

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

    [org.gnome.nautilus.preferences]
    default-folder-viewer='icon-view'
    date-time-format='detailed'
    show-create-link=true

    [org.gnome.nautilus.list-view]
    use-tree-view=true

    [org.gnome.Console]
    ignore-scrollback-limit=true
    shell=['fish']

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
    enabled-extensions=[ 'dash-to-dock@micxgx.gmail.com', 'gsconnect@andyholmes.github.io', 'clipboard-history@alexsaveau.dev', 'notification-timeout@chlumskyvaclav.gmail.com', 'lockscreen-studio@pedro.projects', 'extension-list@tu.berry', 'kimpanel@kde.org', 'Vitals@CoreCoding.com', 'user-theme@gnome-shell-extensions.gcampax.github.com', 'caffeine@patapon.info' ]

    # Material GNOME Shell 主题（user-themes 加载，kimpanel 候选窗等跟随此主题）。
    [org.gnome.shell.extensions.user-theme]
    name='Material-Gnome'
  '';
}
