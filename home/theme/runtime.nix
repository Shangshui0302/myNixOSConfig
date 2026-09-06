{
  config,
  inputs,
  lib,
  materialAdwTheme,
  pkgs,
  ...
}:

let
  homeDir = config.home.homeDirectory;
  defaultWallpaper = ../../assets/nixos_logo.png;
  fcitxMatugenTheme = inputs.fcitx5-matugen-theme.packages.${pkgs.stdenv.hostPlatform.system}.default;
  fcitxTemplateRoot = "${fcitxMatugenTheme}/share/matugen/fcitx5-matugen-theme";

  # MaterialAdw's upstream config/SVG are data files, while Matugen needs a
  # writable, recolored copy. Keep the source package immutable and derive
  # templates by replacing only its palette literals with Matugen expressions.
  materialAdwMatugenTemplates = pkgs.runCommand "material-adw-matugen-templates" { } ''
    mkdir -p "$out"

    ${pkgs.gnused}/bin/sed \
      -e 's|#0F1416|__MATUGEN_SURFACE__|g' \
      -e 's|#171C1E|__MATUGEN_SURFACE_LOW__|g' \
      -e 's|#1B2022|__MATUGEN_SURFACE_CONTAINER__|g' \
      -e 's|#252B2D|__MATUGEN_SURFACE_HIGH__|g' \
      -e 's|#303638|__MATUGEN_OUTLINE_VARIANT__|g' \
      -e 's|#84D2E7|__MATUGEN_PRIMARY__|g' \
      -e 's|#BFC4EB|__MATUGEN_SECONDARY__|g' \
      -e 's|#DDE1FF|__MATUGEN_TERTIARY_DIM__|g' \
      -e 's|#DEE3E5|__MATUGEN_ON_SURFACE__|g' \
      -e 's|#FFFFFF|__MATUGEN_ON_PRIMARY__|g' \
      -e 's|#dfdfdf|__MATUGEN_ON_SURFACE__|g' \
      -e 's|#ffffff|__MATUGEN_ON_SURFACE__|g' \
      -e 's|=white|=__MATUGEN_ON_SURFACE__|g' \
      -e 's|__MATUGEN_SURFACE__|{{colors.surface.default.hex}}|g' \
      -e 's|__MATUGEN_SURFACE_LOW__|{{colors.surface_container_low.default.hex}}|g' \
      -e 's|__MATUGEN_SURFACE_CONTAINER__|{{colors.surface_container.default.hex}}|g' \
      -e 's|__MATUGEN_SURFACE_HIGH__|{{colors.surface_container_high.default.hex}}|g' \
      -e 's|__MATUGEN_OUTLINE_VARIANT__|{{colors.outline_variant.default.hex}}|g' \
      -e 's|__MATUGEN_PRIMARY__|{{colors.primary.default.hex}}|g' \
      -e 's|__MATUGEN_SECONDARY__|{{colors.secondary.default.hex}}|g' \
      -e 's|__MATUGEN_TERTIARY_DIM__|{{colors.tertiary_fixed_dim.default.hex}}|g' \
      -e 's|__MATUGEN_ON_SURFACE__|{{colors.on_surface.default.hex}}|g' \
      -e 's|__MATUGEN_ON_PRIMARY__|{{colors.on_primary.default.hex}}|g' \
      "${materialAdwTheme}/share/Kvantum/MaterialAdw/MaterialAdw.kvconfig" \
      > "$out/MaterialAdw.kvconfig"

    ${pkgs.gnused}/bin/sed \
      -e 's|#151B1E|__MATUGEN_SURFACE_LOWEST__|g' \
      -e 's|#0F1416|__MATUGEN_SURFACE__|g' \
      -e 's|#343A3C|__MATUGEN_SURFACE_LOWEST__|g' \
      -e 's|#3F484B|__MATUGEN_SURFACE_CONTAINER_LOW__|g' \
      -e 's|#84D2E7|__MATUGEN_PRIMARY__|g' \
      -e 's|#B2CBD2|__MATUGEN_PRIMARY_CONTAINER__|g' \
      -e 's|#BFC4EB|__MATUGEN_SECONDARY__|g' \
      -e 's|#CEE7EF|__MATUGEN_SECONDARY_CONTAINER__|g' \
      -e 's|#EFF0F1|__MATUGEN_SURFACE_BRIGHT__|g' \
      -e 's|#eff0f1|__MATUGEN_SURFACE_BRIGHT__|g' \
      -e 's|#FCFCFC|__MATUGEN_SURFACE_BRIGHT__|g' \
      -e 's|#fcfcfc|__MATUGEN_SURFACE_BRIGHT__|g' \
      -e 's|#DFDFDF|__MATUGEN_SURFACE_HIGH__|g' \
      -e 's|#dfdfdf|__MATUGEN_ON_SURFACE_VARIANT__|g' \
      -e 's|#C1C1C1|__MATUGEN_OUTLINE__|g' \
      -e 's|#c1c1c1|__MATUGEN_OUTLINE__|g' \
      -e 's|#989898|__MATUGEN_ON_SURFACE_VARIANT__|g' \
      -e 's|#5a5a5a|__MATUGEN_ON_SURFACE_VARIANT__|g' \
      -e 's|#646464|__MATUGEN_ON_SURFACE_VARIANT__|g' \
      -e 's|#525252|__MATUGEN_OUTLINE__|g' \
      -e 's|#666666|__MATUGEN_OUTLINE__|g' \
      -e 's|#B6B6B6|__MATUGEN_OUTLINE__|g' \
      -e 's|#b6b6b6|__MATUGEN_OUTLINE__|g' \
      -e 's|#ACB1BC|__MATUGEN_ON_SURFACE_VARIANT__|g' \
      -e 's|#acb1bc|__MATUGEN_ON_SURFACE_VARIANT__|g' \
      -e 's|#FFB4AB|__MATUGEN_ERROR__|g' \
      -e 's|#FFFFFF|__MATUGEN_ON_SURFACE__|g' \
      -e 's|#ffffff|__MATUGEN_ON_SURFACE__|g' \
      -e 's|#fff\b|__MATUGEN_ON_SURFACE__|g' \
      -e 's|__MATUGEN_SURFACE_LOWEST__|{{colors.surface_container_lowest.default.hex}}|g' \
      -e 's|__MATUGEN_SURFACE__|{{colors.surface.default.hex}}|g' \
      -e 's|__MATUGEN_PRIMARY__|{{colors.primary.default.hex}}|g' \
      -e 's|__MATUGEN_PRIMARY_CONTAINER__|{{colors.primary_container.default.hex}}|g' \
      -e 's|__MATUGEN_SECONDARY__|{{colors.secondary.default.hex}}|g' \
      -e 's|__MATUGEN_SECONDARY_CONTAINER__|{{colors.secondary_container.default.hex}}|g' \
      -e 's|__MATUGEN_SURFACE_BRIGHT__|{{colors.surface_bright.default.hex}}|g' \
      -e 's|__MATUGEN_SURFACE_HIGH__|{{colors.surface_container_high.default.hex}}|g' \
      -e 's|__MATUGEN_OUTLINE__|{{colors.outline.default.hex}}|g' \
      -e 's|__MATUGEN_ON_SURFACE_VARIANT__|{{colors.on_surface_variant.default.hex}}|g' \
      -e 's|__MATUGEN_ERROR__|{{colors.error.default.hex}}|g' \
      -e 's|__MATUGEN_SURFACE_CONTAINER_LOW__|{{colors.surface_container_low.default.hex}}|g' \
      -e 's|__MATUGEN_ON_SURFACE__|{{colors.on_surface.default.hex}}|g' \
      "${materialAdwTheme}/share/Kvantum/MaterialAdw/MaterialAdw.svg" \
      > "$out/MaterialAdw.svg"
  '';

  papirusFolderApply = pkgs.writeShellScript "papirus-folder-apply" ''
    set -eu

    color="''${1:-}"
    [ -n "$color" ] || exit 0

    theme_dir="$HOME/.local/share/icons/Papirus-Matugen"
    if [ ! -f "$theme_dir/index.theme" ]; then
      mkdir -p "$theme_dir"
      cp -a ${pkgs.papirus-icon-theme}/share/icons/Papirus/. "$theme_dir/"
      chmod -R u+w "$theme_dir"
    fi

    PATH="${pkgs.gtk3}/bin:$PATH" ${pkgs.papirus-folders}/bin/papirus-folders \
      -o -C "$color" -t "$theme_dir" >/dev/null 2>&1 || {
      echo "theme-apply: unable to set Papirus folder color '$color'" >&2
    }
  '';

  matugenConfig = pkgs.writeText "matugen-theme-mode.toml" ''
    [config]

    [templates.caelestia]
    input_path = '${./matugen/caelestia-scheme.json.tpl}'
    output_path = '${homeDir}/.local/state/caelestia/scheme.json'

    [templates.noctalia]
    input_path = '${./matugen/noctalia-palette.json.tpl}'
    output_path = '${homeDir}/.config/noctalia/palettes/matugen.json'

    [templates.hyprland]
    input_path = '${./matugen/hyprland-colors.lua.tpl}'
    output_path = '${homeDir}/.cache/wallpaper-colors/hyprland.lua'

    [templates.niri]
    input_path = '${./matugen/niri-colors.kdl.tpl}'
    output_path = '${homeDir}/.config/niri/wallpaper-colors.kdl'

    [templates.gtk3-light]
    input_path = '${../../local-deriv/material-gnome/gtk3-light.tpl}'
    output_path = '${homeDir}/.themes/Material-Gnome-Matugen/gtk-3.0/colors.css'

    [templates.gtk3-dark]
    input_path = '${../../local-deriv/material-gnome/gtk3-dark.tpl}'
    output_path = '${homeDir}/.themes/Material-Gnome-Matugen-Dark/gtk-3.0/colors.css'

    [templates.gtk4-dual]
    input_path = '${../../local-deriv/material-gnome/gtk4-dual.tpl}'
    output_path = '${homeDir}/.themes/Material-Gnome-Matugen/gtk-4.0/colors.css'

    [templates.qtct]
    input_path = '${./matugen/qtct-colors.conf.tpl}'
    output_path = '${homeDir}/.config/qt5ct/colors/matugen.conf'

    [templates.qtct6]
    input_path = '${./matugen/qtct-colors.conf.tpl}'
    output_path = '${homeDir}/.config/qt6ct/colors/matugen.conf'

    [templates.kvantum-config]
    input_path = '${materialAdwMatugenTemplates}/MaterialAdw.kvconfig'
    output_path = '${homeDir}/.config/Kvantum/MaterialAdw/MaterialAdw.kvconfig'

    [templates.kvantum-svg]
    input_path = '${materialAdwMatugenTemplates}/MaterialAdw.svg'
    output_path = '${homeDir}/.config/Kvantum/MaterialAdw/MaterialAdw.svg'

    [templates.kde-colors]
    input_path = '${./matugen/material-adw-colors.colors.tpl}'
    output_path = '${homeDir}/.local/share/color-schemes/MaterialAdwMatugen.colors'

    [templates.papirus-folders]
    input_path = '${./matugen/papirus-color.tpl}'
    output_path = '${homeDir}/.cache/wallpaper-colors/papirus-folder-color'
    colors_to_compare = [
        { name = "black",      color = "#4f4f4f" },
        { name = "blue",       color = "#5294e2" },
        { name = "bluegrey",   color = "#607d8b" },
        { name = "brown",      color = "#ae8e6c" },
        { name = "carmine",    color = "#a30002" },
        { name = "cyan",       color = "#00bcd4" },
        { name = "darkcyan",   color = "#45abb7" },
        { name = "deeporange", color = "#eb6637" },
        { name = "green",      color = "#87b158" },
        { name = "grey",       color = "#8e8e8e" },
        { name = "indigo",     color = "#5c6bc0" },
        { name = "magenta",    color = "#ca71df" },
        { name = "nordic",     color = "#81a1c1" },
        { name = "orange",     color = "#ee923a" },
        { name = "palebrown",  color = "#d1bfae" },
        { name = "paleorange", color = "#eeca8f" },
        { name = "pink",       color = "#f06292" },
        { name = "red",        color = "#e25252" },
        { name = "teal",       color = "#16a085" },
        { name = "violet",     color = "#7e57c2" },
        { name = "white",      color = "#e4e4e4" },
        { name = "yaru",       color = "#676767" },
        { name = "yellow",     color = "#f9bd30" }
    ]
    compare_to = "{{ colors.primary.default.hex }}"
    post_hook = '${papirusFolderApply} {{ closest_color }}'
    index = 1

    [templates.fcitx5-highlight-light]
    input_path = '${fcitxTemplateRoot}/mellow-matugen/highlight.svg.tpl'
    output_path = '${homeDir}/.local/share/fcitx5/themes/mellow-matugen/highlight.svg'

    [templates.fcitx5-highlight-dark]
    input_path = '${fcitxTemplateRoot}/mellow-matugen-dark/highlight.svg.tpl'
    output_path = '${homeDir}/.local/share/fcitx5/themes/mellow-matugen-dark/highlight.svg'

    [templates.fcitx5-colors-light]
    # fcitx5-gtk loads the first theme.conf as a complete file; it does not
    # merge a user-level color fragment with the Nix profile's base theme.
    input_path = '${fcitxTemplateRoot}/mellow-matugen/theme.conf.tpl'
    output_path = '${homeDir}/.local/share/fcitx5/themes/mellow-matugen/theme.conf'

    [templates.fcitx5-colors-dark]
    input_path = '${fcitxTemplateRoot}/mellow-matugen-dark/theme.conf.tpl'
    output_path = '${homeDir}/.local/share/fcitx5/themes/mellow-matugen-dark/theme.conf'
  '';

  themeApply = pkgs.writeShellScript "theme-apply" ''
        set -u

        mode="''${1:-}"
        wallpaper_arg=0
        if [ "$#" -ge 2 ]; then
          wallpaper_arg=1
        fi
        wallpaper="''${2:-}"
        case "$mode" in
          dark)
            color_scheme=prefer-dark
            gtk_theme=Material-Gnome-Matugen-Dark
            fcitx_theme=mellow-matugen-dark
            ;;
          light)
            color_scheme=prefer-light
            gtk_theme=Material-Gnome-Matugen
            fcitx_theme=mellow-matugen
            ;;
          *)
            echo "theme-apply: expected dark or light, got '$mode'" >&2
            exit 2
            ;;
        esac

        if [ -z "$wallpaper" ]; then
          wallpaper="$(${pkgs.waypaper}/bin/waypaper --list 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[0].wallpaper // empty' 2>/dev/null || true)"
        fi
        if [ ! -f "$wallpaper" ]; then
          wallpaper=${defaultWallpaper}
        fi

        mkdir -p "$HOME/.config/qt5ct/colors" "$HOME/.config/qt6ct/colors" \
          "$HOME/.config/Kvantum/MaterialAdw" "$HOME/.local/share/color-schemes"

        matugen_ok=0
        if ${pkgs.matugen}/bin/matugen image "$wallpaper" -m "$mode" -t scheme-content \
          --prefer=saturation -c ${matugenConfig} 2>/dev/null; then
          matugen_ok=1
        elif ${pkgs.matugen}/bin/matugen image "$wallpaper" -m "$mode" -t scheme-content \
          --prefer saturation -c ${matugenConfig}; then
          matugen_ok=1
        else
          failure_message="theme-apply: matugen failed for $wallpaper"
          echo "$failure_message" >&2
          ${pkgs.util-linux}/bin/logger -t theme-apply -p user.err "$failure_message" 2>/dev/null || true
          ${pkgs.libnotify}/bin/notify-send \
            --app-name=theme-apply --urgency=critical --expire-time=10000 \
            "主题切换失败" "$failure_message" 2>/dev/null || true
          exit 1
        fi

        # Dolphin consumes KDE semantic colors separately from the Qt palette.
        # Keep its mutable per-app selector pointed at the Matugen-generated file.
        ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
          --file "$HOME/.config/dolphinrc" \
          --group UiSettings \
          --key ColorScheme \
          MaterialAdwMatugen

        # GTK4 already has both palettes and follows Darkman's portal directly.
        # GTK3 has no color-scheme media query, so select its pre-rendered theme
        # only after Matugen has finished writing both variants.
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"

        # fcitx5-gtk's Wayland client reads Theme directly; it does not select
        # DarkTheme from UseDarkTheme. Keep the complete no-header config here so
        # both the GTK client and server-side ClassicUI see the same mode.
        fcitx_dir="$HOME/.config/fcitx5/conf"
        mkdir -p "$fcitx_dir"
        fcitx_tmp=$(mktemp "$fcitx_dir/.classicui.conf.XXXXXX")
        trap 'rm -f "$fcitx_tmp"' EXIT
        cat > "$fcitx_tmp" <<EOF
    Theme=$fcitx_theme
    DarkTheme=mellow-matugen-dark
    UseDarkTheme=True
    Vertical Candidate List=True
    EOF
        mv "$fcitx_tmp" "$fcitx_dir/classicui.conf"
        trap - EXIT

        # The generated Fcitx SVG and theme.conf are cached by both ClassicUI and
        # fcitx5-gtk. Restart after every successful Matugen run so wallpaper
        # recolors reach GTK embedded candidate windows as well as ClassicUI.
        if [ "$matugen_ok" -eq 1 ] || [ "$wallpaper_arg" -eq 0 ]; then
          ${pkgs.systemd}/bin/systemctl --user restart app-org.fcitx.Fcitx5@autostart.service 2>/dev/null \
            || ${pkgs.fcitx5}/bin/fcitx5-remote --check -r 2>/dev/null || true
        fi

        # Noctalia stores its runtime choice separately from its Nix-managed defaults.
        ${pkgs.noctalia}/bin/noctalia msg theme-mode-set "$mode" 2>/dev/null || true

        if [ "$matugen_ok" -eq 1 ]; then
          if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
            ${pkgs.hyprland}/bin/hyprctl eval "$(cat '${homeDir}/.cache/wallpaper-colors/hyprland.lua')" 2>/dev/null || true
          fi
          ${pkgs.noctalia}/bin/noctalia msg config-reload 2>/dev/null || true
          exit 0
        fi

        exit 1
  '';
in
{
  # Fixed Chengdu coordinates keep sunrise/sunset scheduling independent of Mihomo's
  # proxy exit and avoid making Geoclue a runtime dependency.
  xdg.configFile."darkman/config.yaml".text = ''
    lat: 30.57
    lng: 104.07
    usegeoclue: false
    portal: true
  '';

  # Darkman runs every executable in XDG_DATA_HOME/darkman at startup and on changes.
  xdg.dataFile."darkman/10-theme-apply" = {
    source = themeApply;
    executable = true;
  };
  home.file.".local/bin/theme-apply" = {
    source = themeApply;
    executable = true;
  };

  # Preserve the current all-dark installation on first migration only. Darkman
  # persists later choices in this file and Home Manager must not overwrite them.
  home.activation.setupDarkmanMode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    darkman_cache_dir="$HOME/.cache/darkman"
    darkman_mode_file="$darkman_cache_dir/mode.txt"
    if [ ! -e "$darkman_mode_file" ]; then
      mkdir -p "$darkman_cache_dir"
      printf '%s' dark > "$darkman_mode_file"
      chmod 600 "$darkman_mode_file"
    fi
  '';

  home.packages = [ fcitxMatugenTheme ];

}
