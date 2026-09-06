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
  # The upstream HM module owns the package and links selected templates here.
  fcitxTemplateRoot = "${homeDir}/.config/matugen/templates/fcitx5-matugen-theme";

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

  # Matugen exposes both light and dark values for one image.  Keep one source
  # template and derive the two mode-specific variants at build time so the
  # runtime cache can be populated by a single image analysis.
  mkMatugenModeTemplate = mode: name: source:
    pkgs.runCommand "${name}-${mode}-matugen-template" { } ''
      ${pkgs.gnused}/bin/sed 's/\.default\./.${mode}./g' ${source} > "$out"
    '';

  mkMatugenModeTemplates = mode: {
    caelestia = mkMatugenModeTemplate mode "caelestia-scheme" ./matugen/caelestia-scheme.json.tpl;
    hyprland = mkMatugenModeTemplate mode "hyprland-colors" ./matugen/hyprland-colors.lua.tpl;
    niri = mkMatugenModeTemplate mode "niri-colors" ./matugen/niri-colors.kdl.tpl;
    qtct = mkMatugenModeTemplate mode "qtct-colors" ./matugen/qtct-colors.conf.tpl;
    kdeColors = mkMatugenModeTemplate mode "material-adw-colors" ./matugen/material-adw-colors.colors.tpl;
    papirus = mkMatugenModeTemplate mode "papirus-color" ./matugen/papirus-color.tpl;
    kvantumConfig = mkMatugenModeTemplate mode "material-adw-kvconfig" "${materialAdwMatugenTemplates}/MaterialAdw.kvconfig";
    kvantumSvg = mkMatugenModeTemplate mode "material-adw-svg" "${materialAdwMatugenTemplates}/MaterialAdw.svg";
  };

  matugenModeTemplates = {
    light = mkMatugenModeTemplates "light";
    dark = mkMatugenModeTemplates "dark";
  };

  # Matugen writes here first.  The shell script copies a complete staging tree
  # into a content-addressed cache only after every template succeeded.
  matugenOutputRoot = "${homeDir}/.cache/wallpaper-colors/staging";

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
      exit 1
    }
  '';

  # Matugen exposes `closest_color` to post hooks, not to ordinary templates.
  # Record that resolved Papirus color during staging; the expensive icon-tree
  # recolor is performed later only when the active color actually changes.
  papirusFolderRecord = pkgs.writeShellScript "papirus-folder-record" ''
    set -eu

    output="''${1:-}"
    color="''${2:-}"
    [ -n "$output" ] && [ -n "$color" ] || exit 0
    output_dir="$(${pkgs.coreutils}/bin/dirname "$output")"
    mkdir -p "$output_dir"
    temporary="$(${pkgs.coreutils}/bin/mktemp "$output_dir/.papirus-color.XXXXXX")"
    printf '%s\n' "$color" > "$temporary"
    ${pkgs.coreutils}/bin/mv -f "$temporary" "$output"
  '';

  matugenConfig = pkgs.writeText "matugen-theme-cache.toml" ''
    [config]

    # All outputs go to a private staging tree.  theme-apply moves the complete
    # tree into a wallpaper-keyed cache after Matugen has rendered every file.
    [templates.caelestia-light]
    input_path = '${matugenModeTemplates.light.caelestia}'
    output_path = '${matugenOutputRoot}/light/caelestia/scheme.json'

    [templates.caelestia-dark]
    input_path = '${matugenModeTemplates.dark.caelestia}'
    output_path = '${matugenOutputRoot}/dark/caelestia/scheme.json'

    [templates.noctalia-dual]
    input_path = '${./matugen/noctalia-palette.json.tpl}'
    output_path = '${matugenOutputRoot}/dual/noctalia/palettes/matugen.json'

    [templates.hyprland-light]
    input_path = '${matugenModeTemplates.light.hyprland}'
    output_path = '${matugenOutputRoot}/light/hyprland.lua'

    [templates.hyprland-dark]
    input_path = '${matugenModeTemplates.dark.hyprland}'
    output_path = '${matugenOutputRoot}/dark/hyprland.lua'

    [templates.niri-light]
    input_path = '${matugenModeTemplates.light.niri}'
    output_path = '${matugenOutputRoot}/light/niri-colors.kdl'

    [templates.niri-dark]
    input_path = '${matugenModeTemplates.dark.niri}'
    output_path = '${matugenOutputRoot}/dark/niri-colors.kdl'

    [templates.gtk3-light]
    input_path = '${../../local-deriv/material-gnome/gtk3-light.tpl}'
    output_path = '${matugenOutputRoot}/dual/gtk3-light/colors.css'

    [templates.gtk3-dark]
    input_path = '${../../local-deriv/material-gnome/gtk3-dark.tpl}'
    output_path = '${matugenOutputRoot}/dual/gtk3-dark/colors.css'

    [templates.gtk4-dual]
    input_path = '${../../local-deriv/material-gnome/gtk4-dual.tpl}'
    output_path = '${matugenOutputRoot}/dual/gtk4/colors.css'

    [templates.qt5-light]
    input_path = '${matugenModeTemplates.light.qtct}'
    output_path = '${matugenOutputRoot}/light/qt5ct/colors/matugen.conf'

    [templates.qt5-dark]
    input_path = '${matugenModeTemplates.dark.qtct}'
    output_path = '${matugenOutputRoot}/dark/qt5ct/colors/matugen.conf'

    [templates.qt6-light]
    input_path = '${matugenModeTemplates.light.qtct}'
    output_path = '${matugenOutputRoot}/light/qt6ct/colors/matugen.conf'

    [templates.qt6-dark]
    input_path = '${matugenModeTemplates.dark.qtct}'
    output_path = '${matugenOutputRoot}/dark/qt6ct/colors/matugen.conf'

    [templates.kvantum-light-config]
    input_path = '${matugenModeTemplates.light.kvantumConfig}'
    output_path = '${matugenOutputRoot}/light/Kvantum/MaterialAdw/MaterialAdw.kvconfig'

    [templates.kvantum-dark-config]
    input_path = '${matugenModeTemplates.dark.kvantumConfig}'
    output_path = '${matugenOutputRoot}/dark/Kvantum/MaterialAdw/MaterialAdw.kvconfig'

    [templates.kvantum-light-svg]
    input_path = '${matugenModeTemplates.light.kvantumSvg}'
    output_path = '${matugenOutputRoot}/light/Kvantum/MaterialAdw/MaterialAdw.svg'

    [templates.kvantum-dark-svg]
    input_path = '${matugenModeTemplates.dark.kvantumSvg}'
    output_path = '${matugenOutputRoot}/dark/Kvantum/MaterialAdw/MaterialAdw.svg'

    [templates.kde-colors-light]
    input_path = '${matugenModeTemplates.light.kdeColors}'
    output_path = '${matugenOutputRoot}/light/color-schemes/MaterialAdwMatugen.colors'

    [templates.kde-colors-dark]
    input_path = '${matugenModeTemplates.dark.kdeColors}'
    output_path = '${matugenOutputRoot}/dark/color-schemes/MaterialAdwMatugen.colors'

    [templates.papirus-folders-light]
    input_path = '${matugenModeTemplates.light.papirus}'
    output_path = '${matugenOutputRoot}/light/papirus-folder-color'
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
    compare_to = "{{ colors.primary.light.hex }}"
    post_hook = '${papirusFolderRecord} ${matugenOutputRoot}/light/papirus-folder-color {{ closest_color }}'
    index = 1

    [templates.papirus-folders-dark]
    # Folder icons keep one wallpaper accent across light/dark mode changes;
    # otherwise the nearest Papirus name can oscillate on every toggle.
    input_path = '${matugenModeTemplates.light.papirus}'
    output_path = '${matugenOutputRoot}/dark/papirus-folder-color'
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
    compare_to = "{{ colors.primary.light.hex }}"
    post_hook = '${papirusFolderRecord} ${matugenOutputRoot}/dark/papirus-folder-color {{ closest_color }}'
    index = 1

    [templates.fcitx5-highlight-light]
    input_path = '${fcitxTemplateRoot}/mellow-matugen/highlight.svg.tpl'
    output_path = '${matugenOutputRoot}/light/fcitx5/mellow-matugen/highlight.svg'

    [templates.fcitx5-highlight-dark]
    input_path = '${fcitxTemplateRoot}/mellow-matugen-dark/highlight.svg.tpl'
    output_path = '${matugenOutputRoot}/dark/fcitx5/mellow-matugen-dark/highlight.svg'

    [templates.fcitx5-colors-light]
    # fcitx5-gtk loads the first theme.conf as a complete file; it does not
    # merge a user-level color fragment with the Nix profile's base theme.
    input_path = '${fcitxTemplateRoot}/mellow-matugen/theme.conf.tpl'
    output_path = '${matugenOutputRoot}/light/fcitx5/mellow-matugen/theme.conf'

    [templates.fcitx5-colors-dark]
    input_path = '${fcitxTemplateRoot}/mellow-matugen-dark/theme.conf.tpl'
    output_path = '${matugenOutputRoot}/dark/fcitx5/mellow-matugen-dark/theme.conf'
  '';

  # Keep the fast mode-only path safe across Matugen/template upgrades.  It can
  # validate this identity without reading or hashing the current wallpaper.
  cacheIdentity = "theme-cache-v3|${pkgs.matugen}|${matugenConfig}|${toString inputs.fcitx5-matugen-theme}";

  themeApply = pkgs.writeShellScript "theme-apply" ''
        set -eu

        mode="''${1:-}"
        wallpaper_arg=0
        if [ "$#" -ge 2 ]; then
          wallpaper_arg=1
        fi
        wallpaper="''${2:-}"

        set_mode() {
          case "$1" in
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
              echo "theme-apply: expected dark or light, got '$1'" >&2
              exit 2
              ;;
          esac
        }
        set_mode "$mode"

        log() {
          echo "theme-apply: $*" >&2
        }
        now_ms() {
          ${pkgs.coreutils}/bin/date +%s%3N
        }

        cache_root="$HOME/.cache/wallpaper-colors"
        cache_index="$cache_root/current-key"
        staging_dir="$cache_root/staging"
        cache_store="$cache_root/cache"
        applied_papirus="$cache_root/applied-papirus-color"
        cache_identity="${cacheIdentity}"
        mkdir -p "$cache_root" "$cache_store"

        # ponytail: one global lock serializes theme applies; split per-key
        # locks only if concurrent producers become measurable.
        # One lock covers staging, cache publication, and activation.  A
        # wallpaper render can never partially overwrite a mode-only switch.
        exec 9>"$cache_root/.lock"
        ${pkgs.util-linux}/bin/flock 9

        required_files="
          light/caelestia/scheme.json
          dark/caelestia/scheme.json
          dual/noctalia/palettes/matugen.json
          light/hyprland.lua
          dark/hyprland.lua
          light/niri-colors.kdl
          dark/niri-colors.kdl
          dual/gtk3-light/colors.css
          dual/gtk3-dark/colors.css
          dual/gtk4/colors.css
          light/qt5ct/colors/matugen.conf
          dark/qt5ct/colors/matugen.conf
          light/qt6ct/colors/matugen.conf
          dark/qt6ct/colors/matugen.conf
          light/Kvantum/MaterialAdw/MaterialAdw.kvconfig
          dark/Kvantum/MaterialAdw/MaterialAdw.kvconfig
          light/Kvantum/MaterialAdw/MaterialAdw.svg
          dark/Kvantum/MaterialAdw/MaterialAdw.svg
          light/color-schemes/MaterialAdwMatugen.colors
          dark/color-schemes/MaterialAdwMatugen.colors
          light/papirus-folder-color
          dark/papirus-folder-color
          light/fcitx5/mellow-matugen/highlight.svg
          dark/fcitx5/mellow-matugen-dark/highlight.svg
          light/fcitx5/mellow-matugen/theme.conf
          dark/fcitx5/mellow-matugen-dark/theme.conf
        "

        validate_outputs() {
          root="$1"
          for relative in $required_files; do
            [ -f "$root/$relative" ] || return 1
          done
        }

        validate_cache() {
          root="$1"
          [ -f "$root/manifest" ] || return 1
          ${pkgs.gnugrep}/bin/grep -Fqx "cache-identity=$cache_identity" "$root/manifest" || return 1
          validate_outputs "$root"
        }

        copy_atomic() {
          source="$1"
          destination="$2"
          [ -f "$source" ] || {
            log "missing generated file: $source"
            return 1
          }
          destination_dir="$(${pkgs.coreutils}/bin/dirname "$destination")"
          mkdir -p "$destination_dir"
          temporary="$(${pkgs.coreutils}/bin/mktemp "$destination_dir/.theme-apply.XXXXXX")"
          ${pkgs.coreutils}/bin/cp -p "$source" "$temporary"
          ${pkgs.coreutils}/bin/mv -f "$temporary" "$destination"
        }

        write_atomic() {
          destination="$1"
          value="$2"
          destination_dir="$(${pkgs.coreutils}/bin/dirname "$destination")"
          mkdir -p "$destination_dir"
          temporary="$(${pkgs.coreutils}/bin/mktemp "$destination_dir/.theme-apply.XXXXXX")"
          printf '%s\n' "$value" > "$temporary"
          ${pkgs.coreutils}/bin/mv -f "$temporary" "$destination"
        }

        resolve_wallpaper() {
          if [ -z "$wallpaper" ]; then
            wallpaper="$(${pkgs.waypaper}/bin/waypaper --list 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[0].wallpaper // empty' 2>/dev/null || true)"
          fi
          if [ ! -f "$wallpaper" ]; then
            wallpaper=${defaultWallpaper}
          fi
        }

        previous_key=""
        if [ -s "$cache_index" ]; then
          previous_key="$(${pkgs.coreutils}/bin/head -n 1 "$cache_index")"
          case "$previous_key" in
            *[!a-f0-9]*) previous_key="" ;;
          esac
        fi

        cache_key=""
        cache_dir=""
        # A normal Darkman toggle trusts current-key and does not even read the
        # wallpaper.  Waypaper passes an explicit path and always re-hashes it.
        if [ "$wallpaper_arg" -eq 0 ] && [ -n "$previous_key" ] \
          && validate_cache "$cache_store/$previous_key"; then
          cache_key="$previous_key"
          cache_dir="$cache_store/$cache_key"
          log "cache=hit key=$cache_key source=current-key"
        else
          resolve_wallpaper
          wallpaper_hash="$(${pkgs.coreutils}/bin/sha256sum "$wallpaper" | ${pkgs.coreutils}/bin/cut -d ' ' -f 1)"
          cache_key="$(printf '%s\n' "''${wallpaper_hash}|$cache_identity" \
            | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -c 1-64)"
          cache_dir="$cache_store/$cache_key"
          log "wallpaper=$wallpaper key=$cache_key"
        fi

        assets_changed=1
        if [ "$cache_key" = "$previous_key" ] && validate_cache "$cache_dir"; then
          assets_changed=0
        fi

        if ! validate_cache "$cache_dir"; then
          resolve_wallpaper
          log "cache=miss generating dual-mode outputs"
          ${pkgs.coreutils}/bin/rm -rf -- "$staging_dir"
          mkdir -p "$staging_dir/light" "$staging_dir/dark" "$staging_dir/dual"

          matugen_start="$(now_ms)"
          if ! ${pkgs.matugen}/bin/matugen image "$wallpaper" -m "$mode" -t scheme-content \
            --prefer=saturation -c ${matugenConfig} 2>/dev/null; then
            if ! ${pkgs.matugen}/bin/matugen image "$wallpaper" -m "$mode" -t scheme-content \
              --prefer saturation -c ${matugenConfig}; then
              failure_message="theme-apply: matugen failed for $wallpaper"
              echo "$failure_message" >&2
              ${pkgs.util-linux}/bin/logger -t theme-apply -p user.err "$failure_message" 2>/dev/null || true
              ${pkgs.libnotify}/bin/notify-send \
                --app-name=theme-apply --urgency=critical --expire-time=10000 \
                "主题切换失败" "$failure_message" 2>/dev/null || true
              exit 1
            fi
          fi
          matugen_end="$(now_ms)"
          log "stage=matugen duration_ms=$((matugen_end - matugen_start))"

          if ! validate_outputs "$staging_dir"; then
            failure_message="theme-apply: incomplete Matugen staging tree"
            echo "$failure_message" >&2
            ${pkgs.util-linux}/bin/logger -t theme-apply -p user.err "$failure_message" 2>/dev/null || true
            exit 1
          fi

          temporary_cache="$cache_store/.new-$cache_key-$$"
          ${pkgs.coreutils}/bin/rm -rf -- "$temporary_cache"
          mkdir -p "$temporary_cache"
          ${pkgs.coreutils}/bin/cp -a "$staging_dir/." "$temporary_cache/"
          printf 'cache-version=3\ncache-identity=%s\nwallpaper-sha256=%s\n' \
            "$cache_identity" "''${wallpaper_hash:-unknown}" \
            > "$temporary_cache/manifest"
          # validate_cache failed above; remove the stale destination before
          # publishing. GNU mv otherwise nests the temporary directory inside
          # an existing cache directory instead of replacing it.
          ${pkgs.coreutils}/bin/rm -rf -- "$cache_dir"
          ${pkgs.coreutils}/bin/mv -f "$temporary_cache" "$cache_dir"
          log "cache=published key=$cache_key"
        fi

        # The explicit wallpaper path may have spent several seconds rendering;
        # apply whichever mode Darkman currently considers authoritative.
        if [ "$wallpaper_arg" -eq 1 ]; then
          latest_mode="$(${pkgs.darkman}/bin/darkman get 2>/dev/null || true)"
          case "$latest_mode" in
            dark|light)
              mode="$latest_mode"
              set_mode "$mode"
              ;;
          esac
        fi

        # Shared files are copied only when the wallpaper key changes.  In
        # particular this prevents Noctalia's file watcher from reloading on a
        # plain dark/light toggle.
        if [ "$assets_changed" -eq 1 ]; then
          copy_atomic "$cache_dir/dual/noctalia/palettes/matugen.json" \
            "$HOME/.config/noctalia/palettes/matugen.json"
          copy_atomic "$cache_dir/dual/gtk3-light/colors.css" \
            "$HOME/.themes/Material-Gnome-Matugen/gtk-3.0/colors.css"
          copy_atomic "$cache_dir/dual/gtk3-dark/colors.css" \
            "$HOME/.themes/Material-Gnome-Matugen-Dark/gtk-3.0/colors.css"
          copy_atomic "$cache_dir/dual/gtk4/colors.css" \
            "$HOME/.themes/Material-Gnome-Matugen/gtk-4.0/colors.css"
          copy_atomic "$cache_dir/light/fcitx5/mellow-matugen/highlight.svg" \
            "$HOME/.local/share/fcitx5/themes/mellow-matugen/highlight.svg"
          copy_atomic "$cache_dir/light/fcitx5/mellow-matugen/theme.conf" \
            "$HOME/.local/share/fcitx5/themes/mellow-matugen/theme.conf"
          copy_atomic "$cache_dir/dark/fcitx5/mellow-matugen-dark/highlight.svg" \
            "$HOME/.local/share/fcitx5/themes/mellow-matugen-dark/highlight.svg"
          copy_atomic "$cache_dir/dark/fcitx5/mellow-matugen-dark/theme.conf" \
            "$HOME/.local/share/fcitx5/themes/mellow-matugen-dark/theme.conf"
        fi

        copy_atomic "$cache_dir/$mode/caelestia/scheme.json" \
          "$HOME/.local/state/caelestia/scheme.json"
        copy_atomic "$cache_dir/$mode/hyprland.lua" \
          "$HOME/.cache/wallpaper-colors/hyprland.lua"
        copy_atomic "$cache_dir/$mode/niri-colors.kdl" \
          "$HOME/.config/niri/wallpaper-colors.kdl"
        copy_atomic "$cache_dir/$mode/qt5ct/colors/matugen.conf" \
          "$HOME/.config/qt5ct/colors/matugen.conf"
        copy_atomic "$cache_dir/$mode/qt6ct/colors/matugen.conf" \
          "$HOME/.config/qt6ct/colors/matugen.conf"
        copy_atomic "$cache_dir/$mode/Kvantum/MaterialAdw/MaterialAdw.kvconfig" \
          "$HOME/.config/Kvantum/MaterialAdw/MaterialAdw.kvconfig"
        copy_atomic "$cache_dir/$mode/Kvantum/MaterialAdw/MaterialAdw.svg" \
          "$HOME/.config/Kvantum/MaterialAdw/MaterialAdw.svg"
        copy_atomic "$cache_dir/$mode/color-schemes/MaterialAdwMatugen.colors" \
          "$HOME/.local/share/color-schemes/MaterialAdwMatugen.colors"
        copy_atomic "$cache_dir/$mode/papirus-folder-color" \
          "$cache_root/papirus-folder-color"

        # Dolphin consumes KDE semantic colors separately from the Qt palette.
        ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
          --file "$HOME/.config/dolphinrc" \
          --group UiSettings \
          --key ColorScheme \
          MaterialAdwMatugen

        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"

        # fcitx5-gtk's Wayland client reads Theme directly; keep the complete
        # user config but avoid restarting the daemon when only the mode changed.
        fcitx_dir="$HOME/.config/fcitx5/conf"
        mkdir -p "$fcitx_dir"
        fcitx_tmp="$(${pkgs.coreutils}/bin/mktemp "$fcitx_dir/.classicui.conf.XXXXXX")"
        trap 'rm -f "$fcitx_tmp"' EXIT
        cat > "$fcitx_tmp" <<EOF
    Theme=$fcitx_theme
    DarkTheme=mellow-matugen-dark
    UseDarkTheme=True
    Vertical Candidate List=True
    EOF
        ${pkgs.coreutils}/bin/mv -f "$fcitx_tmp" "$fcitx_dir/classicui.conf"
        trap - EXIT

        papirus_target="$(cat "$cache_dir/$mode/papirus-folder-color")"
        papirus_current=""
        if [ -f "$applied_papirus" ]; then
          papirus_current="$(cat "$applied_papirus")"
        fi
        if [ "$papirus_target" != "$papirus_current" ]; then
          papirus_start="$(now_ms)"
          if ${papirusFolderApply} "$papirus_target"; then
            write_atomic "$applied_papirus" "$papirus_target"
          else
            log "stage=papirus status=failed color=$papirus_target"
          fi
          papirus_end="$(now_ms)"
          log "stage=papirus duration_ms=$((papirus_end - papirus_start)) color=$papirus_target"
        else
          log "stage=papirus cache-hit color=$papirus_target"
        fi

        fcitx_start="$(now_ms)"
        if [ "$assets_changed" -eq 1 ]; then
          ${pkgs.systemd}/bin/systemctl --user restart app-org.fcitx.Fcitx5@autostart.service 2>/dev/null \
            || ${pkgs.fcitx5}/bin/fcitx5-remote --check -r 2>/dev/null || true
        elif ! ${pkgs.fcitx5}/bin/fcitx5-remote --check -r 2>/dev/null; then
          ${pkgs.systemd}/bin/systemctl --user restart app-org.fcitx.Fcitx5@autostart.service 2>/dev/null || true
        fi
        fcitx_end="$(now_ms)"
        log "stage=fcitx duration_ms=$((fcitx_end - fcitx_start)) mode=$mode assets_changed=$assets_changed"

        if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
          ${pkgs.hyprland}/bin/hyprctl eval "$(cat "$HOME/.cache/wallpaper-colors/hyprland.lua")" 2>/dev/null || true
        fi

        noctalia_start="$(now_ms)"
        ${pkgs.noctalia}/bin/noctalia msg theme-mode-set "$mode" 2>/dev/null || true
        noctalia_end="$(now_ms)"
        log "stage=noctalia duration_ms=$((noctalia_end - noctalia_start))"

        write_atomic "$cache_index" "$cache_key"
        log "complete mode=$mode key=$cache_key assets_changed=$assets_changed"
        exit 0
  '';
in
{
  home.packages = [ pkgs.matugen ];

  programs.fcitx5-matugen = {
    enable = true;
    themeSet = "both";
    style = "blur";
    installMatugenTemplates = true;
  };

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

}
