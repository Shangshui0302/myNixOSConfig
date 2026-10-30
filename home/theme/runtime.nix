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
      ${pkgs.gnused}/bin/sed \
        -e 's/\.default\./.${mode}./g' \
        -e 's/__MATUGEN_MODE__/${mode}/g' ${source} > "$out"
    '';

  mkMatugenModeTemplates = mode: {
    # CLI requires a known name/flavour and variant; dynamic/default accepts
    # external colours, with content matching our Matugen scheme-content.
    caelestia = mkMatugenModeTemplate mode "caelestia-scheme" ./matugen/caelestia-scheme.json.tpl;
    hyprland = mkMatugenModeTemplate mode "hyprland-colors" ./matugen/hyprland-colors.lua.tpl;
    niri = mkMatugenModeTemplate mode "niri-colors" ./matugen/niri-colors.kdl.tpl;
    modernz = mkMatugenModeTemplate mode "modernz" ./matugen/modernz.conf.tpl;
    zellij = mkMatugenModeTemplate mode "zellij-theme" ./matugen/zellij-theme.kdl.tpl;
    qtct = mkMatugenModeTemplate mode "qtct-colors" ./matugen/qtct-colors.conf.tpl;
    kdeColors = mkMatugenModeTemplate mode "material-adw-colors" ./matugen/material-adw-colors.colors.tpl;
    papirus = mkMatugenModeTemplate mode "papirus-color" ./matugen/papirus-color.tpl;
    kvantumConfig = mkMatugenModeTemplate mode "material-adw-kvconfig" "${materialAdwMatugenTemplates}/MaterialAdw.kvconfig";
    kvantumSvg = mkMatugenModeTemplate mode "material-adw-svg" "${materialAdwMatugenTemplates}/MaterialAdw.svg";
    # Strata has no dark/light variant inside one theme file, so light and dark
    # are rendered as separate files of the same id; theme-apply publishes the
    # current mode's file.  It reloads themes only at startup.
    strata = mkMatugenModeTemplate mode "strata-theme" ./matugen/strata-theme.toml.tpl;
  };

  matugenModeTemplates = {
    light = mkMatugenModeTemplates "light";
    dark = mkMatugenModeTemplates "dark";
  };

  # btop runs in the dark Foot terminal, so it always consumes Matugen's dark palette.
  btopDarkTemplate = mkMatugenModeTemplate "dark" "btop-theme" ./matugen/btop.theme.tpl;
  # Yazi runs in the same dark Foot terminal and keeps a dark background while
  # its semantic accents follow the wallpaper palette.
  yaziDarkTemplate = mkMatugenModeTemplate "dark" "yazi-flavor" ./matugen/yazi-flavor.toml.tpl;
  # Neovim consumes a small Lua palette for its dashboard and statusline.
  nvimColorsTemplate = mode: mkMatugenModeTemplate mode "nvim-colors" ./matugen/nvim-colors.lua.tpl;

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

    papirus_identity="$(${pkgs.coreutils}/bin/basename "${pkgs.papirus-icon-theme}")"
    papirus_cache_dir="$HOME/.cache/wallpaper-colors/papirus/v1/$papirus_identity/$color"
    papirus_cache="$papirus_cache_dir/icon-theme.cache"
    mkdir -p "$papirus_cache_dir"

    # DISABLE_UPDATE_ICON_CACHE also skips papirus-folders' KDE cache cleanup.
    # Keep that invalidation, but avoid its full GTK cache scan on every color.
    ${pkgs.coreutils}/bin/rm -f \
      "$HOME/.cache/icon-cache.kcache" \
      "/var/tmp/kdecache-$USER/icon-cache.kcache" 2>/dev/null || true

    PATH="${pkgs.gtk3}/bin:$PATH" DISABLE_UPDATE_ICON_CACHE=1 \
      ${pkgs.papirus-folders}/bin/papirus-folders \
      -o -C "$color" -t "$theme_dir" >/dev/null 2>&1 || {
      echo "theme-apply: unable to set Papirus folder color '$color'" >&2
      exit 1
    }

    if [ -s "$papirus_cache" ]; then
      temporary="$(${pkgs.coreutils}/bin/mktemp "$theme_dir/.icon-theme.cache.XXXXXX")"
      ${pkgs.coreutils}/bin/cp -p "$papirus_cache" "$temporary"
      ${pkgs.coreutils}/bin/mv -f "$temporary" "$theme_dir/icon-theme.cache"
      printf '%s\n' cache-hit
      exit 0
    fi

    # A cache miss is intentionally the slow path.  Remove the previous
    # color's index so a failed rebuild cannot be mistaken for a valid cache.
    ${pkgs.coreutils}/bin/rm -f "$theme_dir/icon-theme.cache"
    ${pkgs.gtk3}/bin/gtk-update-icon-cache -qf "$theme_dir" >/dev/null 2>&1 || true
    if [ ! -s "$theme_dir/icon-theme.cache" ]; then
      echo "theme-apply: unable to rebuild Papirus GTK icon cache" >&2
      exit 1
    fi

    temporary="$(${pkgs.coreutils}/bin/mktemp "$papirus_cache_dir/.icon-theme.cache.XXXXXX")"
    ${pkgs.coreutils}/bin/cp -p "$theme_dir/icon-theme.cache" "$temporary"
    ${pkgs.coreutils}/bin/mv -f "$temporary" "$papirus_cache"
    printf '%s\n' cache-rebuild
  '';

  # Matugen exposes `closest_color` to post hooks, not to ordinary templates.
  # Record that resolved Papirus color during staging; the folder-link update
  # is performed later only when the active color actually changes.
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

    [templates.zellij-light]
    input_path = '${matugenModeTemplates.light.zellij}'
    output_path = '${matugenOutputRoot}/light/zellij/theme.kdl'

    [templates.zellij-dark]
    input_path = '${matugenModeTemplates.dark.zellij}'
    output_path = '${matugenOutputRoot}/dark/zellij/theme.kdl'

    [templates.btop-dark]
    input_path = '${btopDarkTemplate}'
    output_path = '${matugenOutputRoot}/dark/btop.theme'

    [templates.yazi-dark]
    input_path = '${yaziDarkTemplate}'
    output_path = '${matugenOutputRoot}/dark/yazi/flavor.toml'

    [templates.strata-light]
    input_path = '${matugenModeTemplates.light.strata}'
    output_path = '${matugenOutputRoot}/light/strata/themes/matugen.toml'

    [templates.strata-dark]
    input_path = '${matugenModeTemplates.dark.strata}'
    output_path = '${matugenOutputRoot}/dark/strata/themes/matugen.toml'

    [templates.modernz-light]
    input_path = '${matugenModeTemplates.light.modernz}'
    output_path = '${matugenOutputRoot}/light/mpv/script-opts/modernz.conf'

    [templates.modernz-dark]
    input_path = '${matugenModeTemplates.dark.modernz}'
    output_path = '${matugenOutputRoot}/dark/mpv/script-opts/modernz.conf'

    [templates.nvim-colors-light]
    input_path = '${nvimColorsTemplate "light"}'
    output_path = '${matugenOutputRoot}/light/nvim-colors.lua'

    [templates.nvim-colors-dark]
    input_path = '${nvimColorsTemplate "dark"}'
    output_path = '${matugenOutputRoot}/dark/nvim-colors.lua'

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
  cacheIdentity = "theme-cache-v4|${pkgs.matugen}|${matugenConfig}|${toString inputs.fcitx5-matugen-theme}";

  themeApply = pkgs.writeShellScript "theme-apply" (builtins.replaceStrings
    [ "@cacheIdentity@" "@defaultWallpaper@" "@matugenConfig@" "@papirusFolderApply@" "@pkgs_coreutils@" "@pkgs_darkman@" "@pkgs_diffutils@" "@pkgs_fcitx5@" "@pkgs_gawk@" "@pkgs_glib@" "@pkgs_gnugrep@" "@pkgs_hyprland@" "@pkgs_jq@" "@pkgs_kdePackages_kconfig@" "@pkgs_libnotify@" "@pkgs_matugen@" "@pkgs_noctalia@" "@pkgs_procps@" "@pkgs_systemd@" "@pkgs_util_linux@" "@pkgs_waypaper@" ]
    [ "${cacheIdentity}" "${defaultWallpaper}" "${matugenConfig}" "${papirusFolderApply}" "${pkgs.coreutils}" "${pkgs.darkman}" "${pkgs.diffutils}" "${pkgs.fcitx5}" "${pkgs.gawk}" "${pkgs.glib}" "${pkgs.gnugrep}" "${pkgs.hyprland}" "${pkgs.jq}" "${pkgs.kdePackages.kconfig}" "${pkgs.libnotify}" "${pkgs.matugen}" "${pkgs.noctalia}" "${pkgs.procps}" "${pkgs.systemd}" "${pkgs.util-linux}" "${pkgs.waypaper}" ]
    (builtins.readFile ./scripts/theme-apply.sh));
in
{
  home.packages = [ pkgs.matugen ];

  programs.fcitx5-matugen = {
    enable = true;
    themeSet = "both";
    style = "blur";
    installMatugenTemplates = true;
  };

  xdg.configFile."fish/completions/darkman.fish".source =
    "${pkgs.darkman}/share/fish/vendor_completions.d/darkman.fish";

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

  # Home Manager activation may refresh writable runtime assets (notably
  # Fcitx5 themes) from their immutable packages. Reconcile them with the
  # current Matugen cache after all links/runtime copies have been installed.
  home.activation.applyRuntimeTheme =
  lib.hm.dag.entryAfter [
    "writeBoundary"
    "linkGeneration"
    "installFcitx5MatugenRuntimeThemes"
    "setupMatugenGtkTheme"
    "setupKvantumMaterialAdw"
    "setupDarkmanMode"
  ] ''
    if [ -n "''${XDG_RUNTIME_DIR:-}" ] && [ -x "$HOME/.local/bin/theme-apply" ]; then
      mode="$(${pkgs.darkman}/bin/darkman get 2>/dev/null || true)"

      if [ "$mode" != "dark" ] && [ "$mode" != "light" ]; then
        mode="$(cat "$HOME/.cache/darkman/mode.txt" 2>/dev/null || printf '%s' dark)"
      fi

      "$HOME/.local/bin/theme-apply" "$mode"
    fi
  '';

}
