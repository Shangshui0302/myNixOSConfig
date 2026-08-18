{ config, pkgs, ... }:

let
  homeDir = config.home.homeDirectory;
in
{
  home.packages = with pkgs; [
    grim slurp wl-clipboard grimblast swappy wdisplays
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

  # HM 模块 enable 只为拿副作用（fish 补全 + .luarc.json Lua LSP）；
  # 主配置走下方裸 xdg.configFile 写 lua（用 hl.* 自定义函数，HM settings 表达不了），
  # force=true 覆盖 HM 用空 settings 生成的空 hyprland.lua。
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    systemd.enable = false;
    portalPackage = null;
  };

  # stylix 配色注入（替代 Noctalia 模板）：hyprland.lua require stylix-colors，
  # 合成器 border 配色与 foot/终端同源（config.lib.stylix.colors 壁纸取色）。
  xdg.configFile."hypr/stylix-colors.lua".text = ''
    hl.config({
      general = {
        ["col.active_border"] = "${config.lib.stylix.colors.withHashtag.base0D}",
        ["col.inactive_border"] = "${config.lib.stylix.colors.withHashtag.base03}",
      },
      group = {
        ["col.border_active"] = "${config.lib.stylix.colors.withHashtag.base0D}",
        ["col.border_inactive"] = "${config.lib.stylix.colors.withHashtag.base03}",
        ["col.border_locked_active"] = "${config.lib.stylix.colors.withHashtag.base0C}",
        ["col.border_locked_inactive"] = "${config.lib.stylix.colors.withHashtag.base03}",
        groupbar = {
          ["col.active"] = "${config.lib.stylix.colors.withHashtag.base0D}",
          ["col.inactive"] = "${config.lib.stylix.colors.withHashtag.base03}",
          ["col.locked_active"] = "${config.lib.stylix.colors.withHashtag.base0C}",
          ["col.locked_inactive"] = "${config.lib.stylix.colors.withHashtag.base03}",
        },
      },
    })
  '';

  xdg.configFile."hypr/hyprland.lua" = {
    force = true;  # generated from nix, no manual edits to preserve
    text = ''
    local home = "${homeDir}"

    -- stylix 配色（壁纸取色，与 foot/终端同源）
    pcall(require, "stylix-colors")

    hl.env("XCURSOR_SIZE", "24")
    hl.env("HYPRCURSOR_SIZE", "24")

    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.5 })

    hl.config({

      general = {
        gaps_in = 5,
        gaps_out = 5,
        border_size = 2,
        resize_on_border = true,
        allow_tearing = false,
        layout = "scrolling",
      },

      decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 0.88,
        inactive_opacity = 0.82,
        shadow = {
          enabled = true,
          range = 4,
          render_power = 3,
          color = "rgba(1a1a1aee)",
        },
        blur = {
          enabled = true,
          size = 15,
          passes = 4,
          vibrancy = 0.3,
          ignore_opacity = true,
          popups = true,
          popups_ignorealpha = 0.2,
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

      windowrulev2 = {
        "float, class:^(org.gnome.NautilusPreviewer)$",
        "center, class:^(org.gnome.NautilusPreviewer)$",
        "size 70% 70%, class:^(org.gnome.NautilusPreviewer)$",
        "float, class:^(sushi)$",
        "center, class:^(sushi)$",
        "size 70% 70%, class:^(sushi)$",
      },
    })

    -- Noctalia layer blur: frosted glass for bar / panel / dock / notifications / OSD
    hl.layer_rule({
      name = "noctalia",
      match = {
        namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$",
      },
      no_anim = true,
      ignore_alpha = 0.3,
      blur = true,
      blur_popups = true,
      order = -1,
    })

    -- ===== Animation curves =====
    hl.curve("easeOutQuint",  { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
    hl.curve("linear",         { type = "bezier", points = { {0, 0}, {1, 1} } })
    hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } })
    hl.curve("quick",          { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })
    hl.curve("easeInOutCirc",  { type = "bezier", points = { {0.85, 0}, {0.15, 1} } })
    hl.curve("easeInCirc",     { type = "bezier", points = { {0.55, 0}, {1, 0.45} } })
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

    -- Noctalia 由 systemd user service 拉起（graphical-session.target），此处不再 autostart。

    -- Noctalia theme colors loaded via v5 template system (hyprland-lua user template).

    -- ===== Keybinds =====

    -- Launch
    hl.bind("SUPER + W", hl.dsp.exec_cmd("foot"))
    hl.bind("PRINT", hl.dsp.exec_cmd("screenshot screen"))
    hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("screenshot area"))
    hl.bind("SUPER + E", hl.dsp.exec_cmd("nautilus"))
    hl.bind("SUPER + B", hl.dsp.exec_cmd("google-chrome"))
    hl.bind("SUPER + C", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"))
    hl.bind("SUPER + N", hl.dsp.exec_cmd("foot -e nvim"))
    hl.bind("SUPER + O", hl.dsp.exec_cmd("obsidian"))
    hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
    hl.bind("SUPER + K", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))
    hl.bind("SUPER + comma", hl.dsp.exec_cmd("noctalia msg settings-toggle"))
    -- v5: plugin:workspace-overview not yet available, use window-switcher as alternative
    hl.bind("SUPER + TAB", hl.dsp.exec_cmd("noctalia msg window-switcher"))

    -- Window management
    hl.bind("SUPER + Q", hl.dsp.window.close())
    hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
    hl.bind("SUPER + F", hl.dsp.window.fullscreen({ action = "toggle" }))
    hl.bind("SUPER + P", hl.dsp.window.pseudo())
    hl.bind("SUPER + SHIFT + M", hl.dsp.exit())
    hl.bind("SUPER + TAB", hl.dsp.exec_cmd("noctalia msg window-switcher"))

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

    -- Window resize actions
    hl.bind("SUPER + CTRL + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }))
    hl.bind("SUPER + CTRL + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }))
    hl.bind("SUPER + CTRL + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))
    hl.bind("SUPER + CTRL + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }))

    -- Window resize presets for a 2880x1800 @ 1.5x display.
    -- Hyprland uses logical pixels here, so the effective size is 1920x1200.
    -- relative=false means absolute pixel size (maps to resizewindow x y exact).
    hl.bind("SUPER + CTRL + 1", hl.dsp.window.resize({ x = 192, y = 1200, relative = false }))
    hl.bind("SUPER + CTRL + 2", hl.dsp.window.resize({ x = 384, y = 1200, relative = false }))
    hl.bind("SUPER + CTRL + 3", hl.dsp.window.resize({ x = 576, y = 1200, relative = false }))
    hl.bind("SUPER + CTRL + 4", hl.dsp.window.resize({ x = 768, y = 1200, relative = false }))
    hl.bind("SUPER + CTRL + 5", hl.dsp.window.resize({ x = 960, y = 1200, relative = false }))
    hl.bind("SUPER + CTRL + 6", hl.dsp.window.resize({ x = 1152, y = 1200, relative = false }))
    hl.bind("SUPER + CTRL + 7", hl.dsp.window.resize({ x = 1344, y = 1200, relative = false }))
    hl.bind("SUPER + CTRL + 8", hl.dsp.window.resize({ x = 1536, y = 1200, relative = false }))
    hl.bind("SUPER + CTRL + 9", hl.dsp.window.resize({ x = 1728, y = 1200, relative = false }))
    hl.bind("SUPER + CTRL + 0", hl.dsp.window.resize({ x = 1920, y = 1200, relative = false }))

    -- Window move
    hl.bind("SUPER + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
    hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
    hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
    hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({ direction = "d" }))

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
    hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("noctalia msg brightness-up"), { repeating = true })
    hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"), { repeating = true })

    -- ===== Gestures =====

    -- 3-finger vertical: workspace switch
    hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })

    -- 3-finger horizontal: smooth scroll_move (Task #6)
    hl.gesture({ fingers = 3, direction = "left", action = "scroll_move" })
    hl.gesture({ fingers = 3, direction = "right", action = "scroll_move" })
  '';
  };

  # fcitx5 XDG autostart: 崩溃后自动拉起
  xdg.configFile."systemd/user/app-org.fcitx.Fcitx5@autostart.service.d/restart.conf".text = ''
    [Service]
    Restart=on-failure
    RestartSec=3
  '';
}
