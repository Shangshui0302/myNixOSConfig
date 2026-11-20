#!@runtimeShell@
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
          qt_theme=WhiteSurDark
          fcitx_theme=mellow-matugen-dark
          ;;
        light)
          color_scheme=prefer-light
          gtk_theme=Material-Gnome-Matugen
          qt_theme=WhiteSur
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
    fcitx_pending_file="$cache_root/fcitx-pending"
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
        [ -f "$root/$relative" ] && [ -s "$root/$relative" ] || return 1
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

    # The cache key identifies the source, not the writable destination.
    # copy_atomic restores missing files without waking Noctalia's watcher on a match.
    copy_atomic "$cache_dir/dual/noctalia/palettes/matugen.json" \
      "$HOME/.config/noctalia/palettes/matugen.json"

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
    # select it in the writable settings. A refused update is local to Strata;
    # the remaining theme consumers must still run.
    copy_atomic "$cache_dir/$mode/strata/themes/matugen.toml" \
      "$HOME/.config/strata/themes/matugen.toml"
    if ! @themePython@ @strataSelector@ "$HOME/.config/strata/settings.toml"; then
      log "stage=strata status=settings-assert-failed"
    fi
    copy_atomic "$cache_dir/dark/mpv/script-opts/modernz.conf" \
      "$HOME/.config/mpv/script-opts/modernz.conf"
    zellij_start="$(now_ms)"
    copy_atomic "$cache_dir/$mode/zellij/theme.kdl" \
      "$HOME/.config/zellij/themes/matugen.kdl"
    zellij_end="$(now_ms)"
    log "stage=zellij duration_ms=$((zellij_end - zellij_start)) mode=$mode"
    # Kvantum owns Qt widget shapes and colors. Keep its selector writable so
    # Darkman chooses the packaged WhiteSur pair without recoloring Qt assets.
    # Kvantum reads this selection when an application creates its style.
    printf -v kvantum_config '[General]\ntheme=%s' "$qt_theme"
    write_atomic "$HOME/.config/Kvantum/kvantum.kvconfig" "$kvantum_config"
    copy_atomic "$cache_dir/$mode/papirus-folder-color" \
      "$cache_root/papirus-folder-color"

    # Dolphin consumes KDE semantic colors separately from the Qt palette.
    # Clear any leftover immutable entry from previous NextKDE sessions
    # so kwriteconfig6 can set the WhiteSur scheme without aborting theme-apply.
    if [ -f "$HOME/.config/dolphinrc" ]; then
      @pkgs_gnused@/bin/sed -i 's/^ColorScheme\[\$i\]=/ColorScheme=/' "$HOME/.config/dolphinrc" 2>/dev/null || true
    fi
    @pkgs_kdePackages_kconfig@/bin/kwriteconfig6 \
      --file "$HOME/.config/dolphinrc" \
      --group UiSettings \
      --key ColorScheme \
      "$qt_theme"

    @pkgs_glib@/bin/gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"
    @pkgs_glib@/bin/gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"

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
    fcitx_config_changed="$(@themePython@ @fcitxSelector@ "$HOME/.config/fcitx5/conf/classicui.conf" "$fcitx_theme")"
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

    # Refresh decision:
    # Separate file publishing state from refresh success state. If systemctl and
    # fcitx5-remote both fail, record the pending refresh action so the next
    # theme-apply retries the refresh even if files on disk are already identical.
    fcitx_pending=""
    if [ -f "$fcitx_pending_file" ]; then
      fcitx_pending="$(cat "$fcitx_pending_file")"
    fi

    if [ "$fcitx_assets_changed" -eq 1 ] || [ "$fcitx_pending" = "restart" ]; then
      if @pkgs_systemd@/bin/systemctl --user try-restart app-org.fcitx.Fcitx5@autostart.service 2>/dev/null \
        || @pkgs_fcitx5@/bin/fcitx5-remote --check -r 2>/dev/null; then
        @pkgs_coreutils@/bin/rm -f "$fcitx_pending_file"
        log "stage=fcitx action=restart assets_changed=$fcitx_assets_changed"
      else
        write_atomic "$fcitx_pending_file" "restart"
        log "stage=fcitx action=restart status=failed"
      fi
    elif [ "$fcitx_config_changed" -eq 1 ] || [ "$fcitx_pending" = "reload" ]; then
      if @pkgs_fcitx5@/bin/fcitx5-remote --check -r 2>/dev/null \
        || @pkgs_systemd@/bin/systemctl --user try-restart app-org.fcitx.Fcitx5@autostart.service 2>/dev/null; then
        @pkgs_coreutils@/bin/rm -f "$fcitx_pending_file"
        log "stage=fcitx action=reload config_changed=$fcitx_config_changed mode=$mode"
      else
        write_atomic "$fcitx_pending_file" "reload"
        log "stage=fcitx action=reload status=failed mode=$mode"
      fi
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
