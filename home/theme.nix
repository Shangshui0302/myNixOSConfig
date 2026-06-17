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

  # MS CJK font aliases with native-first fallback chains.
  # When native MS fonts are installed (via home.activation → ~/.local/share/fonts/MS/),
  # fontconfig resolves to the real font. When not installed, falls back to open-source
  # alternatives that were configured during evaluation.
  xdg.configFile."fontconfig/conf.d/20-ms-office-cjk.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <!-- Serif -->
      <alias><family>SimSun</family>
        <prefer><family>SimSun</family><family>Noto Serif CJK SC</family></prefer></alias>
      <alias><family>NSimSun</family>
        <prefer><family>NSimSun</family><family>Noto Serif CJK SC</family></prefer></alias>
      <alias><family>宋体</family>
        <prefer><family>SimSun</family><family>Noto Serif CJK SC</family></prefer></alias>

      <!-- Sans -->
      <alias><family>SimHei</family>
        <prefer><family>SimHei</family><family>Noto Sans CJK SC</family></prefer></alias>
      <alias><family>Microsoft YaHei</family>
        <prefer><family>Microsoft YaHei</family><family>Noto Sans CJK SC</family></prefer></alias>
      <alias><family>微软雅黑</family>
        <prefer><family>Microsoft YaHei</family><family>Noto Sans CJK SC</family></prefer></alias>
      <alias><family>黑体</family>
        <prefer><family>SimHei</family><family>Noto Sans CJK SC</family></prefer></alias>

      <!-- Kai -->
      <alias><family>KaiTi</family>
        <prefer><family>KaiTi</family><family>AR PL UKai CN</family></prefer></alias>
      <alias><family>楷体</family>
        <prefer><family>KaiTi</family><family>AR PL UKai CN</family></prefer></alias>

      <!-- FangSong -->
      <alias><family>FangSong</family>
        <prefer><family>FangSong</family><family>AR PL UMing CN</family></prefer></alias>
      <alias><family>仿宋</family>
        <prefer><family>FangSong</family><family>AR PL UMing CN</family></prefer></alias>

      <!-- Serif (Latin) -->
      <alias><family>Times New Roman</family>
        <prefer><family>Times New Roman</family><family>Noto Serif CJK SC</family></prefer></alias>

      <!-- DengXian -->
      <alias><family>DengXian</family>
        <prefer><family>DengXian</family><family>Noto Sans CJK SC</family></prefer></alias>
      <alias><family>等线</family>
        <prefer><family>DengXian</family><family>Noto Sans CJK SC</family></prefer></alias>
    </fontconfig>
  '';

  # Default font families — Source Han Serif (源明朝) for UI/reading,
  # JetBrainsMono Nerd Font for terminal/code.
  # CJK fallback: when a character is missing, fontconfig walks the list
  # and picks the first font that has the glyph.
  # Times New Roman covers Latin glyphs; Source Han Serif covers CJK.
  xdg.configFile."fontconfig/conf.d/30-default-fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <!-- Sans-serif (UI, apps) — strong binding so it wins over system defaults -->
      <match target="pattern">
        <test name="family"><string>sans-serif</string></test>
        <edit name="family" mode="prepend" binding="strong">
          <string>Source Han Serif</string>
          <string>PingFang SC</string>
          <string>Noto Sans CJK SC</string>
          <string>HarmonyOS Sans SC</string>
        </edit>
      </match>

      <!-- Serif (body text, reading) — Times New Roman for Latin, Source Han Serif for CJK -->
      <match target="pattern">
        <test name="family"><string>serif</string></test>
        <edit name="family" mode="prepend" binding="strong">
          <string>Times New Roman</string>
          <string>Source Han Serif</string>
          <string>Noto Serif CJK SC</string>
        </edit>
      </match>

      <!-- Monospace (terminal, code editor) -->
      <match target="pattern">
        <test name="family"><string>monospace</string></test>
        <edit name="family" mode="prepend" binding="strong">
          <string>JetBrainsMono Nerd Font</string>
          <string>Sarasa Mono SC</string>
          <string>Noto Sans CJK SC</string>
        </edit>
      </match>
    </fontconfig>
  '';

  # Extra fonts & Qt5 theme
  home.packages = with pkgs; [
    source-han-serif
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
