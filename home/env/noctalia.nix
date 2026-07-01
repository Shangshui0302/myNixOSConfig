{ config, pkgs, inputs, ... }:

let
  darkModeScript = pkgs.writeShellScript "noctalia-darkmode-toggle" ''
    DCONF="${pkgs.dconf}/bin/dconf"
    if [ "$NOCTALIA_THEME_MODE" = "dark" ]; then
      $DCONF write /org/gnome/desktop/interface/gtk-theme "'adw-gtk3-dark'"
      $DCONF write /org/gnome/desktop/interface/gtk-application-prefer-dark-theme "true"
      mkdir -p ~/.config/qt5ct
      printf '[Appearance]\nstyle=Fusion\ncolor_scheme=darker\n' > ~/.config/qt5ct/qt5ct.conf
    else
      $DCONF write /org/gnome/desktop/interface/gtk-theme "'adw-gtk3'"
      $DCONF write /org/gnome/desktop/interface/gtk-application-prefer-dark-theme "false"
      mkdir -p ~/.config/qt5ct
      printf '[Appearance]\nstyle=Fusion\n' > ~/.config/qt5ct/qt5ct.conf
    fi
  '';
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;

    settings = {
      shell = {
        font_family = "Anthropic Serif Web Text";
        time_format = "{:%H:%M}";
        date_format = "%A, %x";
        telemetry_enabled = false;
        show_location = true;
        clipboard_enabled = true;
        clipboard_auto_paste = "auto";
        password_style = "default";
        avatar_path = "${config.home.homeDirectory}/Pictures/ProfiePictures/yamadaRyou_glassesHeadsphone.jpg";
      };

      shell.animation = {
        speed = 1.0;
      };

      shell.shadow = {
        direction = "down";
      };

      shell.panel = {
        borders = true;
      };

      wallpaper = {
        enabled = true;
        fill_mode = "crop";
        directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
        transition = ["fade" "wipe" "disc" "stripes" "zoom" "honeycomb"];
        transition_duration = 1500;
        transition_on_startup = false;
      };

      wallpaper.default.path = "${config.home.homeDirectory}/Pictures/Wallpapers/yamadaryou.png";

      theme = {
        mode = "auto";
        source = "custom";
        custom_palette = "yamadaryou";
      };

      theme.templates = {
        enable_builtin_templates = true;
        enable_community_templates = false;
        builtin_ids = ["hyprland" "qt" "steam" "telegram" "gtk"];
      };

      # v5: user template key names must be valid TOML bare keys (no hyphens); use underscore
      theme.templates.user.hyprland_lua = {
        input_path = "${config.xdg.configHome}/noctalia/templates/hyprland-colors.lua";
        output_path = "${config.xdg.configHome}/hypr/noctalia-colors.lua";
      };

      bar.main = {
        position = "top";
        thickness = 8;
        background_opacity = 0.93;
        radius = 12;
        # v5: margin_h/margin_v replaced by margin_ends (inset from ends) / margin_edge (distance from screen edge)
        margin_ends = 4;
        margin_edge = 4;
        padding = 2;
        widget_spacing = 6;
        shadow = true;
        capsule = true;
        reserve_space = true;
        start = ["launcher" "clock" "sysmon" "media"];
        center = ["active_window" "workspaces"];
        end = ["tray" "battery" "volume" "brightness" "notifications" "control-center" "session"];
      };

      widget.clock = {
        format = "{:%H:%M %a, %b %d}";
        tooltip_format = "{:%A, %B %d, %Y}";
      };

      widget.launcher = {
        glyph = "rocket";
      };

      widget."control-center" = {
        glyph = "noctalia";
      };

      widget.active_window = {
        max_length = 280.0;
        display = "icon_and_text";
      };

      widget.sysmon = {
        stat = "cpu_usage";
        display = "text";
      };

      widget.media = {
        max_length = 220.0;
        hide_album_art = false;
        hide_when_no_media = false;
      };

      widget.tray = {
        pinned = ["chrome_status_icon_1"];
      };

      widget.notifications = {
        hide_when_no_unread = false;
      };

      widget.workspaces = {
        display = "id";
        labels_only_when_occupied = true;
      };

      widget.battery = {
        # v5: display_mode "glyph" removed; use "icon" (glyph icon) or "graphic" (battery shape)
        display_mode = "icon";
        hide_when_plugged = false;
      };

      widget.volume = {
        show_label = true;
        scroll_step = 5;
      };

      widget.brightness = {
        show_label = true;
        scroll_step = 5;
      };

      widget.privacy = {
        hide_inactive = false;
      };

      widget.network = {
        show_label = true;
      };

      notification = {
        enable_daemon = true;
        layer = "overlay";
        background_opacity = 0.97;
      };

      osd = {
        position = "top";
        background_opacity = 0.97;
      };

      audio = {
        enable_overdrive = false;
      };

      lockscreen = {
        enabled = true;
        blurred_desktop = false;
        blur_intensity = 0.6;
        tint_intensity = 0.0;
      };

      system.monitor.enabled = true;

      dock = {
        enabled = true;
        position = "bottom";
        auto_hide = true;
        pinned = ["qq"];
      };

      location = {
        address = "Chengdu, China";
        auto_locate = false;
      };

      weather = {
        enabled = true;
        effects = true;
        # v5: "celsius" removed; use "metric" (Celsius) or "imperial" (Fahrenheit)
        unit = "metric";
      };

      nightlight = {
        enabled = false;
      };

      # v5: native actions preferred over noctalia: IPC commands for built-in behaviors
      idle.behavior.lock = {
        enabled = true;
        timeout = 600;
        action = "lock";
      };

      idle.behavior.screen-off = {
        enabled = true;
        timeout = 660;
        # v5: native screen_off action; automatically restores monitors on activity (no resume_command needed)
        action = "screen_off";
      };

      # v5: hooks table replaces top-level hooks key
      hooks = {
        theme_mode_changed = "${darkModeScript}";
      };

      greeter_sync = {
        auto_sync = true;
      };

      # v5: [[control_center.shortcuts]] array-of-tables; in Nix HM settings this stays as a list of attrsets
      control_center.shortcuts = [
        { type = "wifi"; }
        { type = "bluetooth"; }
        { type = "nightlight"; }
        { type = "notification"; }
        { type = "wallpaper"; }
      ];
    };
  };

  # yamadaryou wallpaper
  home.file."Pictures/Wallpapers/yamadaryou.png".source = ../../assets/yamadaryou.png;

  # yamadaryou color scheme
  xdg.configFile."noctalia/palettes/yamadaryou.json".text = builtins.toJSON {
    dark = {
      mPrimary = "#ffec15";
      mOnPrimary = "#000000";
      mSecondary = "#006ff1";
      mOnSecondary = "#ffffff";
      mTertiary = "#c57358";
      mOnTertiary = "#e0def4";
      mError = "#ff3092";
      mOnError = "#232136";
      mSurface = "#000000";
      mOnSurface = "#e0e2ef";
      mSurfaceVariant = "#1a1817";
      mOnSurfaceVariant = "#b3b7c2";
      mOutline = "#44415a";
      mShadow = "#232136";
      mHover = "#56526e";
      mOnHover = "#e0def4";
      terminal = {
        normal = {
          black = "#000000";
          red = "#FF3092";
          green = "#11CC40";
          yellow = "#CCBC11";
          blue = "#FFEC15";
          magenta = "#006FF1";
          cyan = "#C57358";
          white = "#E0E2EF";
        };
        bright = {
          black = "#1A1817";
          red = "#FF499F";
          green = "#2CF25E";
          yellow = "#F2E12C";
          blue = "#FFEE2E";
          magenta = "#1983FF";
          cyan = "#EB9B81";
          white = "#FFFFFF";
        };
        foreground = "#E0E2EF";
        background = "#000000";
        selectionFg = "#000000";
        selectionBg = "#FFEC15";
        cursor = "#FFEC15";
        cursorText = "#000000";
      };
    };
    light = {
      mPrimary = "#0055ff";
      mOnPrimary = "#faf4ed";
      mSecondary = "#e6c814";
      mOnSecondary = "#faf4ed";
      mTertiary = "#a36e55";
      mOnTertiary = "#faf4ed";
      mError = "#f52956";
      mOnError = "#faf4ed";
      mSurface = "#fffaf3";
      mOnSurface = "#000000";
      mSurfaceVariant = "#f2e9e1";
      mOnSurfaceVariant = "#353849";
      mOutline = "#dfdad9";
      mShadow = "#faf4ed";
      mHover = "#cecacd";
      mOnHover = "#575279";
      terminal = {
        normal = {
          black = "#FFFAF3";
          red = "#F52956";
          green = "#008C23";
          yellow = "#8C8100";
          blue = "#0055FF";
          magenta = "#E6C814";
          cyan = "#A36E55";
          white = "#000000";
        };
        bright = {
          black = "#F2E9E1";
          red = "#FF446D";
          green = "#13BF3E";
          yellow = "#BFB213";
          blue = "#1966FF";
          magenta = "#FFE130";
          cyan = "#D69F85";
          white = "#333333";
        };
        foreground = "#000000";
        background = "#FFFAF3";
        selectionFg = "#FAF4ED";
        selectionBg = "#0055FF";
        cursor = "#0055FF";
        cursorText = "#FAF4ED";
      };
    };
  };
}
