{ config, pkgs, ... }:

let fonts = import ../pkgs/fonts.nix { inherit pkgs; }; in

{
  # Pointer cursor
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    hyprcursor.enable = true;
    gtk.enable = true;
  };

  # Map MS Office font names to available CJK fonts
  xdg.configFile."fontconfig/conf.d/20-ms-office-cjk.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <alias><family>SimSun</family><prefer><family>Noto Serif CJK SC</family></prefer></alias>
      <alias><family>NSimSun</family><prefer><family>Noto Serif CJK SC</family></prefer></alias>
      <alias><family>SimHei</family><prefer><family>Noto Sans CJK SC</family></prefer></alias>
      <alias><family>Microsoft YaHei</family><prefer><family>Noto Sans CJK SC</family></prefer></alias>
      <alias><family>DengXian</family><prefer><family>Noto Sans CJK SC</family></prefer></alias>
      <alias><family>KaiTi</family><prefer><family>AR PL UKai CN</family></prefer></alias>
      <alias><family>FangSong</family><prefer><family>AR PL UMing CN</family></prefer></alias>
      <alias><family>黑体</family><prefer><family>Noto Sans CJK SC</family></prefer></alias>
      <alias><family>宋体</family><prefer><family>Noto Serif CJK SC</family></prefer></alias>
      <alias><family>楷体</family><prefer><family>AR PL UKai CN</family></prefer></alias>
      <alias><family>仿宋</family><prefer><family>AR PL UMing CN</family></prefer></alias>
      <alias><family>等线</family><prefer><family>Noto Sans CJK SC</family></prefer></alias>
    </fontconfig>
  '';

  # Extra fonts & Qt5 theme
  home.packages = with pkgs; [
    fonts.pingfang-otf
    fonts.harmonyos-sans
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    wqy_microhei
    wqy_zenhei
    wineWow64Packages.fonts
    arphic-ukai
    arphic-uming
    libsForQt5.qt5ct
    papirus-icon-theme gnome-themes-extra adw-gtk3
    # GTK portal .portal file has UseIn=gnome, which blocks it on Hyprland.
    # Provide our own .portal file with Hyprland added so the Settings
    # interface (used by fcitx5 for dark/light theme) gets registered.
    (pkgs.runCommand "gtk-portal-hyprland" { } ''
      mkdir -p $out/share/xdg-desktop-portal/portals
      cat > $out/share/xdg-desktop-portal/portals/gtk.portal << 'PORTALEOF'
[portal]
DBusName=org.freedesktop.impl.portal.desktop.gtk
Interfaces=org.freedesktop.impl.portal.FileChooser;org.freedesktop.impl.portal.AppChooser;org.freedesktop.impl.portal.Print;org.freedesktop.impl.portal.Notification;org.freedesktop.impl.portal.Inhibit;org.freedesktop.impl.portal.Access;org.freedesktop.impl.portal.Account;org.freedesktop.impl.portal.Email;org.freedesktop.impl.portal.DynamicLauncher;org.freedesktop.impl.portal.Lockdown;org.freedesktop.impl.portal.Settings;org.freedesktop.impl.portal.Wallpaper;
UseIn=gnome;Hyprland
PORTALEOF
    '')
  ];

  # GTK4/libadwaita apps need gsettings schemas to read color-scheme
  home.sessionVariables.XDG_DATA_DIRS =
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:\${XDG_DATA_DIRS}";

  # Dark mode defaults
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "Papirus";
      gtk-application-prefer-dark-theme = true;
    };
    "org/nemo/preferences" = {
      show-image-thumbnails = "always";
      thumbnail-limit = 104857600;
    };
  };

}
