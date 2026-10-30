    set -eu

    mode="${1:-}"
    wallpaper_arg=0
    if [ "$#" -ge 2 ]; then
      wallpaper_arg=1
    fi
    wallpaper="${2:-}"

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
      @pkgs_coreutils@/bin/date +%s%3N
    }

    cache_root="$HOME/.cache/wallpaper-colors"
    cache_index="$cache_root/current-key"
    staging_dir="$cache_root/staging"
    cache_store="$cache_root/cache"
    applied_papirus="$cache_root/applied-papirus-color"
    cache_identity="@cacheIdentity@"
    mkdir -p "$cache_root" "$cache_store"

    # ponytail: one global lock serializes theme applies; split per-key
    # locks only if concurrent producers become measurable.
    # One lock covers staging, cache publication, and activation.  A
    # wallpaper render can never partially overwrite a mode-only switch.
    exec 9>"$cache_root/.lock"
    @pkgs_util_linux@/bin/flock 9

    required_files="
      light/caelestia/scheme.json
      dark/caelestia/scheme.json
      dual/noctalia/palettes/matugen.json
      light/hyprland.lua
      dark/hyprland.lua
      light/niri-colors.kdl
      dark/niri-colors.kdl
      light/zellij/theme.kdl
      dark/zellij/theme.kdl
      dark/btop.theme
      dark/yazi/flavor.toml
      light/strata/themes/matugen.toml
      dark/strata/themes/matugen.toml
      light/mpv/script-opts/modernz.conf
      dark/mpv/script-opts/modernz.conf
      light/nvim-colors.lua
      dark/nvim-colors.lua
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
      @pkgs_gnugrep@/bin/grep -Fqx "cache-identity=$cache_identity" "$root/manifest" || return 1
      validate_outputs "$root"
    }

    copy_atomic() {
      source="$1"
      destination="$2"
      [ -f "$source" ] || {
        log "missing generated file: $source"
        return 1
      }
      destination_dir="$(@pkgs_coreutils@/bin/dirname "$destination")"
      mkdir -p "$destination_dir"
      if [ -f "$destination" ] && [ ! -L "$destination" ] && @pkgs_diffutils@/bin/cmp -s "$source" "$destination"; then
        return 0
      fi
      temporary="$(@pkgs_coreutils@/bin/mktemp "$destination_dir/.theme-apply.XXXXXX")"
      @pkgs_coreutils@/bin/cp -p "$source" "$temporary"
      @pkgs_coreutils@/bin/mv -f "$temporary" "$destination"
    }

    write_atomic() {
      destination="$1"
      value="$2"
      destination_dir="$(@pkgs_coreutils@/bin/dirname "$destination")"
      mkdir -p "$destination_dir"
      temporary="$(@pkgs_coreutils@/bin/mktemp "$destination_dir/.theme-apply.XXXXXX")"
      printf '%s\n' "$value" > "$temporary"
      if [ -f "$destination" ] && @pkgs_diffutils@/bin/cmp -s "$temporary" "$destination"; then
        @pkgs_coreutils@/bin/rm -f "$temporary"
        return 0
      fi
      @pkgs_coreutils@/bin/mv -f "$temporary" "$destination"
    }

    resolve_wallpaper() {
      if [ -z "$wallpaper" ]; then
        wallpaper="$(@pkgs_waypaper@/bin/waypaper --list 2>/dev/null | @pkgs_jq@/bin/jq -r '.[0].wallpaper // empty' 2>/dev/null || true)"
      fi
      if [ ! -f "$wallpaper" ]; then
        wallpaper=@defaultWallpaper@
      fi
    }

    previous_key=""
    if [ -s "$cache_index" ]; then
      previous_key="$(@pkgs_coreutils@/bin/head -n 1 "$cache_index")"
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
      wallpaper_hash="$(@pkgs_coreutils@/bin/sha256sum "$wallpaper" | @pkgs_coreutils@/bin/cut -d ' ' -f 1)"
      cache_key="$(printf '%s\n' "${wallpaper_hash}|$cache_identity" \
        | @pkgs_coreutils@/bin/sha256sum | @pkgs_coreutils@/bin/cut -c 1-64)"
      cache_dir="$cache_store/$cache_key"
      log "wallpaper=$wallpaper key=$cache_key"
      if validate_cache "$cache_dir"; then
        log "cache=hit key=$cache_key source=wallpaper"
      fi
    fi

    assets_changed=1
    if [ "$cache_key" = "$previous_key" ] && validate_cache "$cache_dir"; then
      assets_changed=0
    fi

    if ! validate_cache "$cache_dir"; then
      resolve_wallpaper
      log "cache=miss generating dual-mode outputs"
      @pkgs_coreutils@/bin/rm -rf -- "$staging_dir"
      mkdir -p "$staging_dir/light" "$staging_dir/dark" "$staging_dir/dual"

      matugen_start="$(now_ms)"
      if ! @pkgs_matugen@/bin/matugen image "$wallpaper" -m "$mode" -t scheme-content \
        --prefer=saturation -c @matugenConfig@ 2>/dev/null; then
        if ! @pkgs_matugen@/bin/matugen image "$wallpaper" -m "$mode" -t scheme-content \
          --prefer saturation -c @matugenConfig@; then
          failure_message="theme-apply: matugen failed for $wallpaper"
          echo "$failure_message" >&2
          @pkgs_util_linux@/bin/logger -t theme-apply -p user.err "$failure_message" 2>/dev/null || true
          @pkgs_libnotify@/bin/notify-send \
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
        @pkgs_util_linux@/bin/logger -t theme-apply -p user.err "$failure_message" 2>/dev/null || true
        exit 1
      fi

      temporary_cache="$cache_store/.new-$cache_key-$$"
      @pkgs_coreutils@/bin/rm -rf -- "$temporary_cache"
      mkdir -p "$temporary_cache"
      @pkgs_coreutils@/bin/cp -a "$staging_dir/." "$temporary_cache/"
      printf 'cache-version=4\ncache-identity=%s\nwallpaper-sha256=%s\n' \
        "$cache_identity" "${wallpaper_hash:-unknown}" \
        > "$temporary_cache/manifest"
      # validate_cache failed above; remove the stale destination before
      # publishing. GNU mv otherwise nests the temporary directory inside
      # an existing cache directory instead of replacing it.
      @pkgs_coreutils@/bin/rm -rf -- "$cache_dir"
      @pkgs_coreutils@/bin/mv -f "$temporary_cache" "$cache_dir"
      log "cache=published key=$cache_key"
    fi

    # The explicit wallpaper path may have spent several seconds rendering;
    # apply whichever mode Darkman currently considers authoritative.
    if [ "$wallpaper_arg" -eq 1 ]; then
      latest_mode="$(@pkgs_darkman@/bin/darkman get 2>/dev/null || true)"
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
    fi

    # Reconcile GTK even on a mode-only apply: HM may have refreshed its
    # writable theme directories. copy_atomic skips unchanged contents.
    copy_atomic "$cache_dir/dual/gtk3-light/colors.css" \
      "$HOME/.themes/Material-Gnome-Matugen/gtk-3.0/colors.css"
    copy_atomic "$cache_dir/dual/gtk3-dark/colors.css" \
      "$HOME/.themes/Material-Gnome-Matugen-Dark/gtk-3.0/colors.css"
    copy_atomic "$cache_dir/dual/gtk4/colors.css" \
      "$HOME/.themes/Material-Gnome-Matugen/gtk-4.0/colors.css"

    # Publish Neovim's current mode from the wallpaper cache.
    copy_atomic "$cache_dir/$mode/nvim-colors.lua" \
      "$HOME/.cache/matugen/nvim-colors.lua"

    copy_atomic "$cache_dir/$mode/caelestia/scheme.json" \
      "$HOME/.local/state/caelestia/scheme.json"
    copy_atomic "$cache_dir/$mode/hyprland.lua" \
      "$HOME/.cache/wallpaper-colors/hyprland.lua"
    copy_atomic "$cache_dir/$mode/niri-colors.kdl" \
      "$HOME/.config/niri/wallpaper-colors.kdl"
    copy_atomic "$cache_dir/dark/btop.theme" \
      "$HOME/.config/btop/themes/matugen.theme"
    copy_atomic "$cache_dir/dark/yazi/flavor.toml" \
      "$HOME/.config/yazi/flavors/matugen-runtime.yazi/flavor.toml"
    # Strata scans ~/.config/strata/themes/*.toml only at startup (no watcher),
    # uses the file stem as the theme id, and owns settings.toml: it rewrites the
    # whole file on any preference change.  Republish the current mode's theme and
    # rewrite the two top-level keys, the same way Dolphin's ColorScheme is forced
    # below.  The keys are rebuilt instead of patched in place, so a missing
    # trailing newline or duplicate top-level keys cannot survive; file shapes this
    # rewrite cannot handle safely (BOM, indented/quoted keys, indented table
    # headers, multi-line strings) are refused instead of mangled, and the file is
    # only replaced when the content actually differs.  The whole block runs in a
    # subshell so that a failure there cannot abort the rest of theme-apply
    # (mpv/Qt/Kvantum/Dolphin/gsettings/Papirus run after this point).
    copy_atomic "$cache_dir/$mode/strata/themes/matugen.toml" \
      "$HOME/.config/strata/themes/matugen.toml"
    strata_settings="$HOME/.config/strata/settings.toml"
    if ! (
      # Commands here are in an if-condition, so errexit is not inherited; every
      # step that matters therefore fails explicitly through `exit 1`.
      temporary="$(@pkgs_coreutils@/bin/mktemp "$HOME/.config/strata/.settings.toml.XXXXXX")" || exit 1
      trap '@pkgs_coreutils@/bin/rm -f "$temporary"' EXIT
      if [ -f "$strata_settings" ] && [ ! -r "$strata_settings" ]; then
        # Rebuilding from an unreadable file would drop the user's settings.
        exit 1
      fi
      {
        printf '%s\n' 'theme = "matugen"'
        printf '%s\n' 'mode = "theme"'
        if [ -f "$strata_settings" ]; then
          # Only top-level keys are dropped; table-nested ones stay untouched.
          # Shapes this rewrite cannot judge safely (BOM, indented or quoted keys,
          # indented table headers, multi-line strings) are refused: awk exits 3,
          # the `|| exit 1` below keeps the original file untouched.
          @pkgs_gawk@/bin/awk -v sq="'" '
            NR == 1 && index($0, "\357\273\277") == 1 { unsupported = 1 }
            /^[ \t]+\[/ { unsupported = 1 }
            /^[ \t]+"?theme"?[ \t]*=/ { unsupported = 1 }
            /^[ \t]+"?mode"?[ \t]*=/ { unsupported = 1 }
            index($0, "\"\"\"") == 1 { unsupported = 1 }
            index($0, sq sq sq) == 1 { unsupported = 1 }
            /^["\x27](theme|mode)["\x27][ \t]*=/ { unsupported = 1 }
            unsupported { exit 3 }
            /^\[/ { table = 1 }
            !table && /^theme[ \t]*=[ \t]*/ { next }
            !table && /^mode[ \t]*=[ \t]*/ { next }
            { print }
          ' "$strata_settings" || exit 1
        fi
      } > "$temporary" || exit 1
      if [ -f "$strata_settings" ] \
        && @pkgs_diffutils@/bin/cmp -s "$temporary" "$strata_settings"; then
        exit 0
      fi
      if [ -f "$strata_settings" ]; then
        @pkgs_coreutils@/bin/chmod --reference="$strata_settings" "$temporary" 2>/dev/null || true
      fi
      @pkgs_coreutils@/bin/mv -f "$temporary" "$strata_settings" || exit 1
      log "stage=strata status=theme-selected"
    ); then
      log "stage=strata status=settings-assert-failed"
    fi
    copy_atomic "$cache_dir/dark/mpv/script-opts/modernz.conf" \
      "$HOME/.config/mpv/script-opts/modernz.conf"
    zellij_start="$(now_ms)"
    copy_atomic "$cache_dir/$mode/zellij/theme.kdl" \
      "$HOME/.config/zellij/themes/matugen.kdl"
    zellij_end="$(now_ms)"
    log "stage=zellij duration_ms=$((zellij_end - zellij_start)) mode=$mode"
    qt_palette_changed=0
    if ! @pkgs_diffutils@/bin/cmp -s "$cache_dir/$mode/qt5ct/colors/matugen.conf" \
      "$HOME/.config/qt5ct/colors/matugen.conf" || \
      ! @pkgs_diffutils@/bin/cmp -s "$cache_dir/$mode/qt6ct/colors/matugen.conf" \
        "$HOME/.config/qt6ct/colors/matugen.conf"; then
      qt_palette_changed=1
    fi
    copy_atomic "$cache_dir/$mode/qt5ct/colors/matugen.conf" \
      "$HOME/.config/qt5ct/colors/matugen.conf"
    copy_atomic "$cache_dir/$mode/qt6ct/colors/matugen.conf" \
      "$HOME/.config/qt6ct/colors/matugen.conf"
    copy_atomic "$cache_dir/$mode/Kvantum/MaterialAdw/MaterialAdw.kvconfig" \
      "$HOME/.config/Kvantum/MaterialAdw/MaterialAdw.kvconfig"
    copy_atomic "$cache_dir/$mode/Kvantum/MaterialAdw/MaterialAdw.svg" \
      "$HOME/.config/Kvantum/MaterialAdw/MaterialAdw.svg"
    # qtct watches its config directory, not the nested colors/ directory.
    # Notify after both palettes and Kvantum assets are published so long-lived
    # QApplication consumers (including hyprpolkitagent) update without restart.
    if [ "$qt_palette_changed" -eq 1 ]; then
      @pkgs_coreutils@/bin/touch "$HOME/.config/qt5ct" "$HOME/.config/qt6ct"
    fi
    copy_atomic "$cache_dir/$mode/color-schemes/MaterialAdwMatugen.colors" \
      "$HOME/.local/share/color-schemes/MaterialAdwMatugen.colors"
    copy_atomic "$cache_dir/$mode/papirus-folder-color" \
      "$cache_root/papirus-folder-color"

    # Dolphin consumes KDE semantic colors separately from the Qt palette.
    @pkgs_kdePackages_kconfig@/bin/kwriteconfig6 \
      --file "$HOME/.config/dolphinrc" \
      --group UiSettings \
      --key ColorScheme \
      MaterialAdwMatugen

    @pkgs_glib@/bin/gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"
    @pkgs_glib@/bin/gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"

    # xdg-desktop-portal-gtk keeps GTK file chooser state in its long-lived
    # process; reload it after publishing a new wallpaper palette so
    # VS Code/Codex do not retain the previous GTK colors.
    if [ "$assets_changed" -eq 1 ]; then
      portal_start="$(now_ms)"
      @pkgs_systemd@/bin/systemctl --user try-restart xdg-desktop-portal-gtk.service 2>/dev/null || true
      portal_end="$(now_ms)"
      log "stage=portal-gtk duration_ms=$((portal_end - portal_start))"
    fi

    # Update quick, visible consumers before the potentially multi-second
    # Papirus icon-tree work below.  Keep this serial under the global lock
    # so no consumer observes a half-published palette.
    noctalia_start="$(now_ms)"
    @pkgs_noctalia@/bin/noctalia msg theme-mode-set "$mode" 2>/dev/null || true
    noctalia_end="$(now_ms)"
    log "stage=noctalia duration_ms=$((noctalia_end - noctalia_start))"

    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
      @pkgs_hyprland@/bin/hyprctl eval "$(cat "$HOME/.cache/wallpaper-colors/hyprland.lua")" 2>/dev/null || true
    fi

    btop_start="$(now_ms)"
    if [ "$assets_changed" -eq 1 ]; then
      @pkgs_procps@/bin/pkill -USR2 -x btop 2>/dev/null || true
      btop_end="$(now_ms)"
      log "stage=btop duration_ms=$((btop_end - btop_start)) mode=$mode assets_changed=$assets_changed"
    else
      log "stage=btop status=skipped mode=$mode assets_changed=0"
    fi

    fcitx_start="$(now_ms)"
    fcitx_assets_changed=0

    # Sync light/dark mellow-matugen highlight.svg and theme.conf
    if ! @pkgs_diffutils@/bin/cmp -s \
        "$cache_dir/light/fcitx5/mellow-matugen/highlight.svg" \
        "$HOME/.local/share/fcitx5/themes/mellow-matugen/highlight.svg" \
      || ! @pkgs_diffutils@/bin/cmp -s \
        "$cache_dir/light/fcitx5/mellow-matugen/theme.conf" \
        "$HOME/.local/share/fcitx5/themes/mellow-matugen/theme.conf" \
      || ! @pkgs_diffutils@/bin/cmp -s \
        "$cache_dir/dark/fcitx5/mellow-matugen-dark/highlight.svg" \
        "$HOME/.local/share/fcitx5/themes/mellow-matugen-dark/highlight.svg" \
      || ! @pkgs_diffutils@/bin/cmp -s \
        "$cache_dir/dark/fcitx5/mellow-matugen-dark/theme.conf" \
        "$HOME/.local/share/fcitx5/themes/mellow-matugen-dark/theme.conf"; then

      copy_atomic \
        "$cache_dir/light/fcitx5/mellow-matugen/highlight.svg" \
        "$HOME/.local/share/fcitx5/themes/mellow-matugen/highlight.svg"
      copy_atomic \
        "$cache_dir/light/fcitx5/mellow-matugen/theme.conf" \
        "$HOME/.local/share/fcitx5/themes/mellow-matugen/theme.conf"
      copy_atomic \
        "$cache_dir/dark/fcitx5/mellow-matugen-dark/highlight.svg" \
        "$HOME/.local/share/fcitx5/themes/mellow-matugen-dark/highlight.svg"
      copy_atomic \
        "$cache_dir/dark/fcitx5/mellow-matugen-dark/theme.conf" \
        "$HOME/.local/share/fcitx5/themes/mellow-matugen-dark/theme.conf"
      fcitx_assets_changed=1
    fi

    # Write classicui.conf atomically
    fcitx_config_changed=0
    fcitx_dir="$HOME/.config/fcitx5/conf"
    mkdir -p "$fcitx_dir"
    fcitx_tmp="$(@pkgs_coreutils@/bin/mktemp "$fcitx_dir/.classicui.conf.XXXXXX")"
    trap '@pkgs_coreutils@/bin/rm -f "$fcitx_tmp"' EXIT
    cat > "$fcitx_tmp" <<EOF
Theme=$fcitx_theme
DarkTheme=mellow-matugen-dark
UseDarkTheme=True
Vertical Candidate List=True
EOF
    if [ ! -f "$fcitx_dir/classicui.conf" ] \
      || ! @pkgs_diffutils@/bin/cmp -s "$fcitx_tmp" "$fcitx_dir/classicui.conf"; then
      @pkgs_coreutils@/bin/mv -f "$fcitx_tmp" "$fcitx_dir/classicui.conf"
      fcitx_config_changed=1
    else
      @pkgs_coreutils@/bin/rm -f "$fcitx_tmp"
    fi
    trap - EXIT

    # Refresh decision:
    # if fcitx_assets_changed == 1: try-restart daemon (fallback to remote -r)
    # elif fcitx_config_changed == 1: remote -r (fallback to try-restart)
    # else: noop
    if [ "$fcitx_assets_changed" -eq 1 ]; then
      @pkgs_systemd@/bin/systemctl --user try-restart app-org.fcitx.Fcitx5@autostart.service 2>/dev/null \
        || @pkgs_fcitx5@/bin/fcitx5-remote --check -r 2>/dev/null || true
      log "stage=fcitx action=restart assets_changed=1"
    elif [ "$fcitx_config_changed" -eq 1 ]; then
      if ! @pkgs_fcitx5@/bin/fcitx5-remote --check -r 2>/dev/null; then
        @pkgs_systemd@/bin/systemctl --user try-restart app-org.fcitx.Fcitx5@autostart.service 2>/dev/null || true
      fi
      log "stage=fcitx action=reload config_changed=1 mode=$mode"
    else
      log "stage=fcitx action=noop mode=$mode"
    fi
    fcitx_end="$(now_ms)"
    log "stage=fcitx duration_ms=$((fcitx_end - fcitx_start))"

    papirus_target="$(cat "$cache_dir/$mode/papirus-folder-color")"
    papirus_current=""
    if [ -f "$applied_papirus" ]; then
      papirus_current="$(cat "$applied_papirus")"
    fi
    if [ "$papirus_target" != "$papirus_current" ]; then
      papirus_start="$(now_ms)"
      papirus_cache_status="failed"
      if papirus_cache_status="$(@papirusFolderApply@ "$papirus_target")"; then
        write_atomic "$applied_papirus" "$papirus_target"
      else
        log "stage=papirus status=failed color=$papirus_target"
      fi
      papirus_end="$(now_ms)"
      log "stage=papirus duration_ms=$((papirus_end - papirus_start)) color=$papirus_target cache=$papirus_cache_status"
    else
      log "stage=papirus cache-hit color=$papirus_target"
    fi

    write_atomic "$cache_index" "$cache_key"
    log "complete mode=$mode key=$cache_key assets_changed=$assets_changed"
    exit 0
