{ config, pkgs, ... }:

let
  homeDir = config.home.homeDirectory;
in
{
  home.packages = with pkgs; [
    awww swaynotificationcenter libnotify
    grim slurp wl-clipboard grimblast swappy
    waybar wofi
    wofi-emoji typora zettlr kdePackages.ghostwriter
    (let
      cursor-clip-src = pkgs.fetchFromGitHub {
        owner = "Sirulex";
        repo = "cursor-clip";
        rev = "7e12054e55b7b2c34eff8638b88488403686e8dd";
        hash = "sha256-nppWnTJck1pCXucLUOas9mFQKCg7Ck0DENoPA9wUxkI=";
      };
    in cursor-clip.overrideAttrs (old: {
      src = cursor-clip-src;
      cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
        src = cursor-clip-src;
        hash = "sha256-QG9PR5aI76rgP+Z1dtWJvn5IX2t+vvuN6Y4/OKyBjfM=";
      };
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.dbus ];
      PKG_CONFIG_PATH = "${pkgs.dbus.dev}/lib/pkgconfig";
    }))
    # clipse  # 和 cursor-clip 定位冲突，先注释
  ] ++ [
    (pkgs.writeShellScriptBin "clipd-toggle" ''
      if pgrep -f 'cursor-clip$' >/dev/null 2>&1; then
        pkill -f 'cursor-clip$'
      else
        exec cursor-clip
      fi
    '')
    (pkgs.writeShellScriptBin "wofi-emoji-toggle" ''
      if hyprctl clients -j | ${pkgs.jq}/bin/jq -e '.[] | select(.class == "wofi")' >/dev/null 2>&1; then
        hyprctl clients -j | ${pkgs.jq}/bin/jq -r '.[] | select(.class == "wofi") | .address' | while read addr; do
          hyprctl dispatch closewindow "address:$addr"
        done
      else
        (sleep 0.3 && hyprctl dispatch focuswindow "class:wofi") &
        FOCUS_PID=$!
        EMOJI=$(${pkgs.gnused}/bin/sed '1,/^### DATA ###$/d' ${pkgs.wofi-emoji}/bin/wofi-emoji | ${pkgs.wofi}/bin/wofi -p "emoji" --show dmenu -i --normal-window | cut -d ' ' -f 1 | tr -d '\n')
        kill $FOCUS_PID 2>/dev/null
        [ -n "$EMOJI" ] && ${pkgs.wtype}/bin/wtype "$EMOJI"
        [ -n "$EMOJI" ] && ${pkgs.wl-clipboard}/bin/wl-copy "$EMOJI"
      fi
    '')
    (pkgs.writeShellScriptBin "screenshot" ''
      dir="$HOME/Pictures/Screenshots/$(date +%Y-%m)"
      mkdir -p "$dir"
      case "$1" in
        area)
          tmp=$(mktemp /tmp/screenshot-XXXXXX.png)
          trap "rm -f $tmp" EXIT
          ${pkgs.grimblast}/bin/grimblast save area "$tmp" || exit 1
          ${pkgs.swappy}/bin/swappy -f "$tmp"
          file="$dir/$(date +%Y-%m-%d-%H%M%S).png"
          cp "$tmp" "$file"
          ${pkgs.wl-clipboard}/bin/wl-copy < "$file"
          ;;
        *)
          file="$dir/$(date +%Y-%m-%d-%H%M%S).png"
          ${pkgs.grimblast}/bin/grimblast save "$1" "$file"
          ${pkgs.wl-clipboard}/bin/wl-copy < "$file"
          ;;
      esac
    '')
  ];

  wayland.windowManager.hyprland = {
    enable = true;

    settings = { };
  };

  # Noctalia user template: Lua color config
  xdg.configFile."noctalia/templates/hyprland-colors.lua".text = ''
    hl.config({
      general = {
        ["col.active_border"] = "{{colors.primary.default.hex}}",
        ["col.inactive_border"] = "{{colors.surface.default.hex}}",
      },
      group = {
        ["col.border_active"] = "{{colors.secondary.default.hex}}",
        ["col.border_inactive"] = "{{colors.surface.default.hex}}",
        ["col.border_locked_active"] = "{{colors.error.default.hex}}",
        ["col.border_locked_inactive"] = "{{colors.surface.default.hex}}",
        groupbar = {
          ["col.active"] = "{{colors.secondary.default.hex}}",
          ["col.inactive"] = "{{colors.surface.default.hex}}",
          ["col.locked_active"] = "{{colors.error.default.hex}}",
          ["col.locked_inactive"] = "{{colors.surface.default.hex}}",
        },
      },
    })
  '';

  # Noctalia user template registry
  xdg.configFile."noctalia/user-templates.toml".text = ''
    [templates.hyprland-lua]
    input_path = "~/.config/noctalia/templates/hyprland-colors.lua"
    output_path = "~/.config/hypr/noctalia-colors.lua"
  '';

  xdg.configFile."hypr/hyprland.lua".text = ''
    local home = "${homeDir}"

    -- Noctalia theme colors (generated on first theme load, safe-require)
    pcall(require, "noctalia-colors")

    hl.env("XCURSOR_SIZE", "24")
    hl.env("HYPRCURSOR_SIZE", "24")

    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.5 })

    hl.config({

      general = {
        gaps_in = 5,
        gaps_out = 20,
        border_size = 2,
        resize_on_border = true,
        allow_tearing = false,
        layout = "scrolling",
      },

      decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
          enabled = true,
          range = 4,
          render_power = 3,
          color = "rgba(1a1a1aee)",
        },
        blur = {
          enabled = true,
          size = 12,
          passes = 3,
          vibrancy = 0.1,
        },
      },

      animations = {
        enabled = true,
        workspace_wraparound = true,
      },

      scrolling = {
        column_width = 0.5,
        direction = "right",
        follow_focus = true,
        fullscreen_on_one_column = true,
        explicit_column_widths = "0.33, 0.5, 0.67, 0.81, 0.96",
      },

      master = {
        new_status = "master",
      },

      misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = false,
      },

      xwayland = {
        force_zero_scaling = true,
      },

      input = {
        kb_layout = "us",
        kb_options = "caps:escape",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
          natural_scroll = true,
        },
      },

      device = {
        {
          name = "epic-mouse-v1",
          sensitivity = -0.5,
        },
      },

      binds = {
        drag_threshold = 10,
        workspace_back_and_forth = true,
        allow_workspace_cycles = true,
      },
    })

    -- ===== Animation curves =====
    hl.curve("easeOutQuint",  { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
    hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
    hl.curve("linear",         { type = "bezier", points = { {0, 0}, {1, 1} } })
    hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } })
    hl.curve("quick",          { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })
    hl.curve("easeInOutCirc",  { type = "bezier", points = { {0.85, 0}, {0.15, 1} } })
    hl.curve("easeInCirc",     { type = "bezier", points = { {0.55, 0}, {1, 0.45} } })
    hl.curve("easeOutCirc",    { type = "bezier", points = { {0, 0.55}, {0.45, 1} } })

    -- ===== Animations =====
    hl.animation({ leaf = "global",    enabled = true, speed = 10, bezier = "linear" })
    hl.animation({ leaf = "border",    enabled = true, speed = 5.39, bezier = "easeOutQuint" })
    hl.animation({ leaf = "windows",   enabled = true, speed = 4.79, bezier = "easeOutQuint" })
    hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
    hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear",        style = "popin 87%" })
    hl.animation({ leaf = "fadeIn",    enabled = true, speed = 3.0,  bezier = "easeInCirc" })
    hl.animation({ leaf = "fadeOut",   enabled = true, speed = 1.46, bezier = "almostLinear" })
    hl.animation({ leaf = "fade",      enabled = true, speed = 3.03, bezier = "quick" })
    hl.animation({ leaf = "layers",    enabled = true, speed = 3.81, bezier = "easeOutQuint" })
    hl.animation({ leaf = "layersIn",  enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
    hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5,  bezier = "linear",        style = "fade" })
    hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
    hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
    hl.animation({ leaf = "workspaces",    enabled = true, speed = 9,   bezier = "easeInOutCirc", style = "slidefadevert" })
    hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.8, bezier = "easeInOutCirc", style = "slidevert" })
    hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.8, bezier = "easeInOutCirc", style = "slidevert" })
    hl.animation({ leaf = "specialWorkspace",    enabled = true, speed = 9,   bezier = "easeInOutCirc", style = "fade" })
    hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 3.6, bezier = "quick",          style = "fade" })
    hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 1.8, bezier = "easeInOutCirc", style = "fade" })
    hl.animation({ leaf = "zoomFactor",  enabled = true, speed = 7, bezier = "quick" })

    -- Startup commands
    hl.on("hyprland.start", function()
      hl.exec_cmd("fcitx5 -rd")
      hl.exec_cmd("noctalia-shell")
      hl.exec_cmd(home .. "/.cache/noctalia/HVE/hve_watchdog.sh")
      hl.exec_cmd("cursor-clip --daemon &")
    end)

    -- Noctalia colors/overlay not loaded (hyprlang .conf incompatible with Lua).

    -- ===== Keybinds =====

    -- Launch
    hl.bind("SUPER + W", hl.dsp.exec_cmd("foot"))
    hl.bind("PRINT", hl.dsp.exec_cmd("screenshot screen"))
    hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("screenshot area"))
    hl.bind("SUPER + E", hl.dsp.exec_cmd("nemo"))
    hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("noctalia-shell ipc call launcher toggle"))
    hl.bind("SUPER + K", hl.dsp.exec_cmd("noctalia-shell ipc call controlCenter toggle"))
    hl.bind("SUPER + comma", hl.dsp.exec_cmd("noctalia-shell ipc call settings toggle"))
    hl.bind("SUPER + TAB", hl.dsp.exec_cmd("noctalia-shell ipc call plugin:workspace-overview toggle"))
    hl.bind("SUPER + period", hl.dsp.exec_cmd("wofi-emoji-toggle"))
    hl.bind("SUPER + C", hl.dsp.exec_cmd("clipd-toggle"))

    -- Window management
    hl.bind("SUPER + Q", hl.dsp.window.close())
    hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
      hl.bind("SUPER + F", hl.dsp.window.fullscreen({ action = "toggle" }))
    hl.bind("SUPER + P", hl.dsp.window.pseudo())
    hl.bind("SUPER + SHIFT + M", hl.dsp.exit())

    -- Focus
    hl.bind("SUPER + left", hl.dsp.focus({ direction = "l" }))
    hl.bind("SUPER + right", hl.dsp.focus({ direction = "r" }))
    hl.bind("SUPER + up", hl.dsp.focus({ direction = "u" }))
    hl.bind("SUPER + down", hl.dsp.focus({ direction = "d" }))

    -- Workspace
    hl.bind("SUPER + 1", hl.dsp.focus({ workspace = 1 }))
    hl.bind("SUPER + 2", hl.dsp.focus({ workspace = 2 }))
    hl.bind("SUPER + 3", hl.dsp.focus({ workspace = 3 }))
    hl.bind("SUPER + 4", hl.dsp.focus({ workspace = 4 }))
    hl.bind("SUPER + 5", hl.dsp.focus({ workspace = 5 }))
    hl.bind("SUPER + 6", hl.dsp.focus({ workspace = 6 }))
    hl.bind("SUPER + 7", hl.dsp.focus({ workspace = 7 }))
    hl.bind("SUPER + 8", hl.dsp.focus({ workspace = 8 }))
    hl.bind("SUPER + 9", hl.dsp.focus({ workspace = 9 }))
    hl.bind("SUPER + 0", hl.dsp.focus({ workspace = 10 }))

    -- Move to workspace
    hl.bind("SUPER + SHIFT + 1", hl.dsp.window.move({ workspace = "1" }))
    hl.bind("SUPER + SHIFT + 2", hl.dsp.window.move({ workspace = "2" }))
    hl.bind("SUPER + SHIFT + 3", hl.dsp.window.move({ workspace = "3" }))
    hl.bind("SUPER + SHIFT + 4", hl.dsp.window.move({ workspace = "4" }))
    hl.bind("SUPER + SHIFT + 5", hl.dsp.window.move({ workspace = "5" }))
    hl.bind("SUPER + SHIFT + 6", hl.dsp.window.move({ workspace = "6" }))
    hl.bind("SUPER + SHIFT + 7", hl.dsp.window.move({ workspace = "7" }))
    hl.bind("SUPER + SHIFT + 8", hl.dsp.window.move({ workspace = "8" }))
    hl.bind("SUPER + SHIFT + 9", hl.dsp.window.move({ workspace = "9" }))
    hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = "10" }))

    -- Special workspace
    hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"))
    hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

    -- Window resize
    hl.bind("SUPER + SHIFT + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }))
    hl.bind("SUPER + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }))
    hl.bind("SUPER + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))
    hl.bind("SUPER + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }))

    -- Window move
    hl.bind("SUPER + CTRL + left", hl.dsp.window.move({ direction = "l" }))
    hl.bind("SUPER + CTRL + right", hl.dsp.window.move({ direction = "r" }))
    hl.bind("SUPER + CTRL + up", hl.dsp.window.move({ direction = "u" }))
    hl.bind("SUPER + CTRL + down", hl.dsp.window.move({ direction = "d" }))

    -- Window swap
    hl.bind("SUPER + ALT + left", hl.dsp.window.swap({ direction = "l" }))
    hl.bind("SUPER + ALT + right", hl.dsp.window.swap({ direction = "r" }))
    hl.bind("SUPER + ALT + up", hl.dsp.window.swap({ direction = "u" }))
    hl.bind("SUPER + ALT + down", hl.dsp.window.swap({ direction = "d" }))

    -- Mouse workspace scroll
    hl.bind("SUPER + mouse_down", function()
      hl.dispatch(hl.dsp.focus({ workspace = "e+1" }))
    end)
    hl.bind("SUPER + mouse_up", function()
      hl.dispatch(hl.dsp.focus({ workspace = "e-1" }))
    end)

    -- Mouse window drag/resize
    hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
    hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

    -- Media / brightness (long-press for repeating)
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%+"), { repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"), { repeating = true })
    hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
    hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
    hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("noctalia-shell ipc call brightness increase"), { repeating = true })
    hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia-shell ipc call brightness decrease"), { repeating = true })

    -- ===== Gestures =====

    -- 3-finger vertical: workspace switch
    hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })

    -- 3-finger horizontal: smooth scroll_move (Task #6)
    hl.gesture({ fingers = 3, direction = "left", action = "scroll_move" })
    hl.gesture({ fingers = 3, direction = "right", action = "scroll_move" })
  '';
}
