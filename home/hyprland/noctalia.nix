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
  audio = {
    enable_overdrive = false;
    enable_sounds = true;
  };
  bar = {
    order = [
      ("main")
    ];
    main = {
      background_opacity = 0.0;
      capsule = true;
      capsule_opacity = 0.8;
      center = [
        ("group:g4")
        ("active_window")
        ("workspaces")
        ("cat")
      ];
      end = [
        ("group:g6")
        ("tray")
        ("group:g2")
        ("privacy")
        ("group:g1")
      ];
      font_weight = 400;
      margin_edge = 0;
      margin_ends = 0;
      padding = 10;
      position = "top";
      radius = 80;
      reserve_space = true;
      scale = 1.1000000089406967;
      shadow = false;
      start = [
        ("launcher")
        ("clock")
        ("sysmon")
        ("media")
        ("group:g3")
        ("group:g5")
      ];
      thickness = 42;
      widget_spacing = 6;
      dead_zone = {
        actions = {
          middle = "exec noctalia msg settings-toggle";
        };
      };
      capsule_group = [
        ({
          fill = "surface_variant";
          id = "g1";
          members = [
            ("battery")
            ("session")
          ];
          opacity = 0.80000001192092896;
          padding = 6.0;
        })
        ({
          fill = "surface_variant";
          id = "g2";
          members = [
            ("clipboard")
            ("screenshot")
            ("notifications")
            ("control-center")
          ];
          opacity = 0.80000001192092896;
          padding = 6.0;
        })
        ({
          fill = "surface_variant";
          id = "g3";
          members = [
            ("network_tx")
            ("network_rx")
          ];
          opacity = 0.80000001192092896;
          padding = 6.0;
        })
        ({
          fill = "surface_variant";
          id = "g4";
          members = [
            ("taskbar")
          ];
          opacity = 0.80000001192092896;
          padding = 6.0;
        })
        ({
          fill = "surface_variant";
          id = "g5";
          members = [
            ("audio_visualizer")
            ("media")
          ];
          opacity = 1.0;
          padding = 6.0;
        })
        ({
          fill = "surface_variant";
          id = "g6";
          members = [
            ("volume")
            ("brightness")
            ("network")
          ];
          opacity = 0.80000001192092896;
          padding = 6.0;
        })
      ];
    };
  };
  battery = {
    warning_threshold = 20;
  };
  calendar = {
    enabled = true;
    account = {
      personal_google = {
        type = "google";
      };
    };
  };
  control_center = {
    sidebar = "full";
    sidebar_section = "full";
    width = 900;
    shortcuts = [
      ({
        type = "wifi";
      })
      ({
        type = "bluetooth";
      })
      ({
        type = "nightlight";
      })
      ({
        type = "dark_mode";
      })
      ({
        type = "power_profile";
      })
      ({
        type = "clipboard";
      })
    ];
  };
  desktop_widgets = {
    schema_version = 2;
    widget_order = [
      ("desktop-widget-0000000000000003")
    ];
    grid = {
      cell_size = 8;
      major_interval = 4;
      visible = true;
    };
    widget = {
      desktop-widget-0000000000000003 = {
        box_height = 240.0;
        box_width = 256.0;
        cx = 1776.0;
        cy = 1064.0;
        output = "eDP-1";
        rotation = 0.0;
        type = "fancy_audio_visualizer";
        settings = {
          background = false;
          secondary_color = "on_primary";
          visualization_mode = "wave_rings";
        };
      };
    };
  };
  dock = {
    auto_hide = true;
    background_opacity = 0.65999998524785042;
    enabled = true;
    inactive_opacity = 0.99999997764825821;
    inactive_scale = 1.0;
    launcher_icon = "brand-snowflake";
    launcher_position = "start";
    magnification_scale = 1.2000000029802322;
    pinned = [
      ("qq")
    ];
    position = "bottom";
    radius = 20;
    reserve_space = false;
    show_dots = true;
  };
  hooks = {
    theme_mode_changed = "${darkModeScript}";
  };
  hot_corners = {
    enabled = true;
    bottom_left = {
      action = "window_switcher";
    };
    top_left = {
      action = "launcher";
    };
    top_right = {
      action = "control_center";
    };
  };
  idle = {
    behavior = {
      lock = {
        action = "lock";
        enabled = true;
        timeout = 600;
      };
      screen-off = {
        action = "screen_off";
        enabled = true;
        timeout = 660;
      };
    };
  };
  keybinds = {
    down = [
      ("Down")
      ("Alt+j")
    ];
    left = [
      ("Left")
      ("Alt+h")
    ];
    right = [
      ("Right")
      ("Alt+l")
    ];
    up = [
      ("Up")
      ("Alt+k")
    ];
  };
  location = {
    address = "Chengdu, China";
    auto_locate = false;
  };
  lockscreen = {
    blur_intensity = 0.6;
    blurred_desktop = true;
    enabled = true;
    tint_intensity = 0.0;
  };
  lockscreen_widgets = {
    enabled = true;
    schema_version = 2;
    widget_order = [
      ("lockscreen-login-box@eDP-1")
    ];
    grid = {
      cell_size = 8;
      major_interval = 4;
      visible = true;
    };
    widget = {
      "lockscreen-login-box@eDP-1" = {
        box_height = 196.0;
        box_width = 720.0;
        cx = 960.0;
        cy = 1014.0;
        output = "eDP-1";
        rotation = 0.0;
        type = "login_box";
        settings = {
          background_color = "surface_variant";
          background_opacity = 1.0;
          background_radius = 32.0;
          center_password_text = false;
          input_opacity = 1.0;
          input_radius = 32.0;
          layout = "regular";
          show_caps_lock = true;
          show_keyboard_layout = true;
          show_login_button = true;
          show_media = true;
          show_session_buttons = true;
          show_unlock_hint = true;
          show_weather = true;
        };
      };
      lockscreen-widget-0000000000000001 = {
        box_height = 456.0;
        box_width = 688.0;
        cx = 960.0;
        cy = 404.0;
        output = "eDP-1";
        rotation = 0.0;
        type = "clock";
        settings = {
          background = true;
          background_opacity = 0.0;
          background_radius = 32;
          center_text = false;
          color = "primary";
          font_family = ".PingFang SC";
          format = "{:%H:%M}";
          shadow = false;
        };
      };
      lockscreen-widget-0000000000000002 = {
        box_height = 136.0;
        box_width = 248.0;
        cx = 1008.0;
        cy = 664.0;
        output = "eDP-1";
        rotation = 0.0;
        type = "media_player";
        settings = {
          background_opacity = 1.0;
          background_radius = 32;
        };
      };
      lockscreen-widget-0000000000000003 = {
        box_height = 136.0;
        box_width = 144.0;
        cx = 1216.0;
        cy = 664.0;
        output = "eDP-1";
        rotation = 0.0;
        type = "fancy_audio_visualizer";
        settings = {
          background = true;
          background_opacity = 1.0;
          background_radius = 32;
        };
      };
      lockscreen-widget-0000000000000004 = {
        box_height = 296.0;
        box_width = 232.0;
        cx = 752.0;
        cy = 744.0;
        output = "eDP-1";
        rotation = 0.0;
        type = "weather";
        settings = {
          background_opacity = 1.0;
          background_padding = 21;
          background_radius = 32;
          forecast_days = 6;
          shadow = false;
          show_forecast = true;
        };
      };
      lockscreen-widget-0000000000000005 = {
        box_height = 144.0;
        box_width = 192.0;
        cx = 980.0;
        cy = 820.0;
        output = "eDP-1";
        rotation = 0.0;
        type = "sysmon";
        settings = {
          background_opacity = 1.0;
          background_radius = 32;
          shadow = false;
          stat = "cpu_usage";
          stat2 = "cpu_temp";
        };
      };
      lockscreen-widget-0000000000000006 = {
        box_height = 336.0;
        box_width = 688.0;
        cx = 960.0;
        cy = 744.0;
        output = "eDP-1";
        rotation = 0.0;
        type = "label";
        settings = {
          background_radius = 32;
          title = "";
        };
      };
      lockscreen-widget-0000000000000009 = {
        box_height = 144.0;
        box_width = 200.0;
        cx = 1188.0;
        cy = 820.0;
        output = "eDP-1";
        rotation = 0.0;
        type = "sysmon";
        settings = {
          background_opacity = 1.0;
          background_radius = 32;
          shadow = false;
          stat = "ram_pct";
          stat2 = "swap_pct";
        };
      };
      lockscreen-widget-000000000000000a = {
        box_height = 1200.0;
        box_width = 776.0;
        cx = 960.0;
        cy = 600.0;
        output = "eDP-1";
        rotation = 0.0;
        type = "label";
        settings = {
          background_opacity = 0.66;
          background_radius = 0;
          opacity = 0.9500000000000001;
          title = "";
        };
      };
      lockscreen-widget-000000000000000c = {
        box_height = 16.0;
        box_width = 760.0;
        cx = 960.0;
        cy = 1184.0;
        output = "eDP-1";
        rotation = 0.0;
        type = "label";
        settings = {
          background = false;
          background_opacity = 0.66;
          background_radius = 0;
          color = "on_surface_variant";
          description = "NixOS          //          Hyprland          //          Noctalia";
          opacity = 0.56;
          shadow = false;
          title = "";
        };
      };
    };
  };
  nightlight = {
    enabled = false;
  };
  notification = {
    background_opacity = 0.8;
    enable_daemon = true;
    layer = "overlay";
    position = "bottom_right";
  };
  osd = {
    background_opacity = 0.8;
    position = "top_center";
    position_vertical = "center_right";
  };
  plugin_settings = {
    "noctalia/translator" = {
      target_lang = "zh";
    };
  };
  plugins = {
    enabled = [
      ("noctalia/kaomoji")
      ("noctalia/translator")
      ("noctalia/bongocat")
    ];
  };
  shell = {
    app_icon_color = "error";
    avatar_path = "${config.home.homeDirectory}/Pictures/ProfiePictures/yamadaRyou_glassesHeadsphone.jpg";
    clipboard_auto_paste = "auto";
    clipboard_enabled = true;
    corner_radius_scale = 0.80000001192092896;
    date_format = "%A, %x";
    font_family = "Anthropic Serif Web Text";
    launch_apps_as_systemd_services = true;
    password_style = "random";
    polkit_agent = true;
    screen_time_enabled = true;
    settings_show_advanced = true;
    show_location = true;
    telemetry_enabled = false;
    external_ip_enabled = true;
    time_format = "{:%H:%M}";
    animation = {
      speed = 1.0;
    };
    launcher = {
      app_grid = true;
      session_search = true;
    };
    greeter_sync = {
      auto_sync = true;
    };
    panel = {
      borders = true;
      control_center_placement = "floating";
      open_near_click_clipboard = true;
      open_near_click_control_center = true;
      open_near_click_launcher = true;
      open_near_click_session = true;
      open_near_click_wallpaper = true;
      polkit_placement = "attached";
      session_placement = "floating";
      transparency_mode = "glass";
      wallpaper_position = "center";
    };
    screen_corners = {
      enabled = true;
      size = 10;
    };
    screenshot = {
      confirm_region = true;
      directory = "${config.home.homeDirectory}/Pictures/Screenshots/2026-06";
    };
    shadow = {
      direction = "down";
    };
  };
  system = {
    monitor = {
      enabled = true;
    };
  };
  theme = {
    community_palette = "Tokyo Night Moon";
    custom_palette = "yamadaryou";
    mode = "dark";
    source = "custom";
    wallpaper_scheme = "muted";
    templates = {
      builtin_ids = [
        ("hyprland")
        ("qt")
        ("steam")
        ("telegram")
        ("gtk")
      ];
      enable_builtin_templates = true;
      enable_community_templates = true;
      user = {
        hyprland_lua = {
          input_path = "${config.xdg.configHome}/noctalia/templates/hyprland-colors.lua";
          output_path = "${config.xdg.configHome}/hypr/noctalia-colors.lua";
        };
        niri_colors = {
          input_path = "${config.xdg.configHome}/noctalia/templates/niri-colors.kdl";
          output_path = "${config.xdg.configHome}/niri/noctalia-colors.kdl";
        };
      };
    };
  };
  wallpaper = {
    directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
    enabled = true;
    fill_mode = "crop";
    transition = [
      ("fade")
      ("wipe")
      ("disc")
      ("stripes")
      ("zoom")
      ("honeycomb")
    ];
    transition_duration = 1500;
    transition_on_startup = true;
    default = {
      path = "${config.home.homeDirectory}/Pictures/Wallpapers/yamadaryou.png";
    };
    last = {
      path = "${config.home.homeDirectory}/Pictures/Wallpapers/yamadaryou.png";
    };
    monitors = {
      eDP-1 = {
        path = "${config.home.homeDirectory}/Pictures/Wallpapers/yamadaryou.png";
      };
    };
  };
  weather = {
    effects = true;
    enabled = true;
    unit = "metric";
  };
  widget = {
    active_window = {
      display = "icon_and_text";
      max_length = 280.0;
    };
    battery = {
      hide_when_plugged = false;
    };
    brightness = {
      show_label = true;
    };
    cat = {
      color = "error";
      type = "noctalia/bongocat:cat";
    };
    clock = {
      format = "{:%H:%M %A, %Y年%b%d日}";
      tooltip_format = "{:%A, %B %d, %Y}";
    };
    control-center = {
      glyph = "noctalia";
    };
    launcher = {
      glyph = "brand-snowflake";
    };
    media = {
      hide_album_art = false;
      hide_when_no_media = true;
      max_length = 220.0;
    };
    network = {
      show_label = false;
    };
    network_rx = {
      type = "sysmon";
      stat = "net_rx";
      visualization = "none";
      show_value = true;
      glyph = "square-rounded-chevrons-down-filled";
      network_speed_compact = true;
    };
    network_tx = {
      type = "sysmon";
      stat = "net_tx";
      visualization = "none";
      show_value = true;
      glyph = "square-rounded-chevrons-up-filled";
      network_speed_compact = true;
    };
    notifications = {
      hide_when_no_unread = false;
    };
    privacy = {
      hide_inactive = false;
    };
    sysmon = {
      visualization = "graph";
      show_value = true;
      stat = "cpu_usage";
    };
    tray = {
      pinned = [
        ("chrome_status_icon_1")
      ];
    };
    volume = {
      show_label = true;
    };
    workspaces = {
      label_source = "id";
      labels_only_when_occupied = true;
    };
  };
}
;
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
