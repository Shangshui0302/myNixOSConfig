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
        source = "builtin";
        builtin = "Noctalia";
      };

      theme.templates = {
        enable_builtin_templates = true;
        enable_community_templates = false;
      };

      theme.templates.user."hyprland-lua" = {
        input_path = "${config.xdg.configHome}/noctalia/templates/hyprland-colors.lua";
        output_path = "${config.xdg.configHome}/hypr/noctalia-colors.lua";
      };

      bar.main = {
        position = "top";
        thickness = 34;
        background_opacity = 0.93;
        radius = 12;
        margin_h = 4;
        margin_v = 4;
        padding = 14;
        widget_spacing = 6;
        shadow = true;
        capsule = true;
        reserve_space = true;
        start = ["launcher" "clock" "workspaces"];
        center = ["active_window"];
        end = ["media" "sysmon" "network" "bluetooth" "volume" "brightness" "battery" "privacy" "notifications" "tray" "control-center" "session"];
      };

      widget.clock = {
        format = "{:%H:%M %a, %b %d}";
        tooltip_format = "{:%A, %B %d, %Y}";
      };

      widget.launcher = {
        glyph = "search";
      };

      widget.control-center = {
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
        display_mode = "glyph";
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
        position = "top_right";
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
        unit = "celsius";
      };

      nightlight = {
        enabled = false;
      };

      idle.behavior.lock = {
        enabled = true;
        timeout = 600;
        command = "noctalia:session lock";
      };

      idle.behavior.screen-off = {
        enabled = true;
        timeout = 660;
        command = "noctalia:dpms-off";
        resume_command = "noctalia:dpms-on";
      };

      hooks = {
        theme_mode_changed = "${darkModeScript}";
      };

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
}
