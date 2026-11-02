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
in
{
  imports = [ ./qt-whitesur.nix ];

  # Qt keeps WhiteSur's own palette; GTK continues to follow Matugen.
  qt = {
    platformTheme.name = "qtct";
    qt5ctSettings.Appearance = {
      custom_palette = false;
      icon_theme = "Papirus-Matugen";
      style = "kvantum";
    };
    qt6ctSettings.Appearance = config.qt.qt5ctSettings.Appearance;
  };

  dconf.settings."org/gnome/desktop/interface".icon-theme = lib.mkForce "Papirus-Matugen";

  # GTK4 在一个可写主题里常驻双 palette；GTK3 使用两个稳定主题目录。
  home.activation.setupMatugenGtkTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    (
    # Share theme-apply's lock for the entire snapshot and directory replacement.
    cache_root="$HOME/.cache/wallpaper-colors"
    mkdir -p "$cache_root"
    exec 9>"$cache_root/.lock"
    ${pkgs.util-linux}/bin/flock 9

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
    )
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
  # Reclaim the declared theme files after switching desktop variants; no backups.
  home.file.".config/gtk-4.0/gtk.css".force = true;
  home.file.".config/gtk-4.0/gtk-dark.css".force = true;
  home.file.".config/gtk-4.0/colors.css".force = true;

  services.flatpak.overrides.settings.global = {
    Context.filesystems = "$HOME/.themes:ro";
    Environment.GTK_THEME = lib.mkForce matugenThemeName;
  };
}
