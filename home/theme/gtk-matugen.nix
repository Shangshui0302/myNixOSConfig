{
  config,
  lib,
  pkgs,
  materialGnomeTheme,
  ...
}:

let
  matugenThemeName = "Material-Gnome-Matugen";
  matugenDarkThemeName = "${matugenThemeName}-Dark";
  matugenThemeDir = "${config.home.homeDirectory}/.themes/${matugenThemeName}";
  qtAppearance = {
    color_scheme_path = "${config.home.homeDirectory}/.config/qt5ct/colors/matugen.conf";
    custom_palette = true;
    icon_theme = "Papirus-Matugen";
    style = "Breeze";
  };
in
{
  home.packages = [
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

  # qtct 同时提供 Qt5 和 Qt6 平台插件；两者共用 matugen 生成的 QPalette。
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "breeze";
    qt5ctSettings.Appearance = qtAppearance;
    qt6ctSettings.Appearance = qtAppearance;
  };

  dconf.settings."org/gnome/desktop/interface".icon-theme = lib.mkForce "Papirus-Matugen";

  # GTK4 在一个可写主题里常驻双 palette；GTK3 使用两个稳定主题目录。
  # GNOME 变体不 import 本文件，用 gtk-static.nix 保持固定深色。
  home.activation.setupMatugenGtkTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    matugen_theme_dir="${config.home.homeDirectory}/.themes/${matugenThemeName}"
    matugen_theme_next="${config.home.homeDirectory}/.themes/.${matugenThemeName}.next"
    matugen_dark_theme_dir="${config.home.homeDirectory}/.themes/${matugenDarkThemeName}"
    matugen_dark_theme_next="${config.home.homeDirectory}/.themes/.${matugenDarkThemeName}.next"
    mkdir -p "$HOME/.themes"

    chmod -R u+w "$matugen_theme_next" "$matugen_dark_theme_next" 2>/dev/null || true
    rm -rf "$matugen_theme_next" "$matugen_dark_theme_next"
    cp -r ${materialGnomeTheme}/share/themes/Material-Gnome "$matugen_theme_next"
    cp -r ${materialGnomeTheme}/share/themes/Material-Gnome "$matugen_dark_theme_next"
    chmod -R u+w "$matugen_theme_next" "$matugen_dark_theme_next"

    for matugen_colors in gtk-3.0/colors.css gtk-4.0/colors.css; do
      if [ -f "$matugen_theme_dir/$matugen_colors" ]; then
        cp -p "$matugen_theme_dir/$matugen_colors" "$matugen_theme_next/$matugen_colors"
      fi
    done
    if [ -f "$matugen_dark_theme_dir/gtk-3.0/colors.css" ]; then
      cp -p "$matugen_dark_theme_dir/gtk-3.0/colors.css" "$matugen_dark_theme_next/gtk-3.0/colors.css"
    fi

    rm -rf "$matugen_theme_dir" "$matugen_dark_theme_dir"
    mv "$matugen_theme_next" "$matugen_theme_dir"
    mv "$matugen_dark_theme_next" "$matugen_dark_theme_dir"
    chmod -R u+w "$matugen_theme_dir" "$matugen_dark_theme_dir"
  '';

  home.file.".config/gtk-4.0/gtk.css".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink "${matugenThemeDir}/gtk-4.0/gtk.css"
  );
  home.file.".config/gtk-4.0/gtk-dark.css".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink "${matugenThemeDir}/gtk-4.0/gtk-dark.css"
  );
  home.file.".config/gtk-4.0/colors.css".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink "${matugenThemeDir}/gtk-4.0/colors.css"
  );

  services.flatpak.overrides.settings.global = {
    Context.filesystems = "$HOME/.themes:ro";
    Environment.GTK_THEME = lib.mkForce matugenThemeName;
  };
}
