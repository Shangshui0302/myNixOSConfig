{ config, pkgs, ... }:

let
  foot-notify = pkgs.writeShellScriptBin "foot-notify" ''
    title="$1"
    body="$2"
    body="''${body%$'\n'}"

    OUT=$(${pkgs.libnotify}/bin/notify-send --print-id --wait \
      --app-name foot \
      --category terminal \
      --action default="Focus" \
      --hint "string:desktop-entry:foot" \
      -- "$title" "$body")

    echo "$OUT"
    ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow "class:foot" >/dev/null 2>&1 || true
    echo "xdgtoken="
  '';
in

{
  # Hyprland 主桌面特有（GNOME 变体不 import 本文件）。

  # Hyprland 特有环境变量（GNOME Wayland 走原生 text-input-v3，不设这些）
  environment.variables = {
    GTK_IM_MODULE = "fcitx";
    SDL_IM_MODULE = "fcitx";
  };

  environment.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt5ct";
  };

  # Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  xdg.portal = {
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];

    config.hyprland = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
    };

    config.niri = {
      default = [ "wlr" "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
      "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
    };
  };

  # Terminal（foot，Hyprland 默认终端）
  programs.foot = {
    enable = true;
    xdg.serverAutostart = true;
    settings = {
      main = {
        shell = "${pkgs.fish}/bin/fish";
        pad = "10x10 center";
        selection-target = "both";
        bold-text-in-bright = "yes";
      };
      scrollback.lines = 10000;
      bell = {
        urgent = "yes";
        notify = "yes";
      };
      mouse.hide-when-typing = "yes";
      cursor.blink = "yes";
      "desktop-notifications" = {
        command = "${foot-notify}/bin/foot-notify \${title} \${body}";
        inhibit-when-focused = "no";
      };
      # 配色由 stylix 生成（config.lib.stylix.colors，host/hyprland/stylix.nix），
      # blur 是 foot 特效（stylix 不碰）单独保留
      "colors-dark" = {
        blur = "yes";
        alpha = "0.8";
        background = config.lib.stylix.colors.withHashtag.base00;
        foreground = config.lib.stylix.colors.withHashtag.base05;
        regular0 = config.lib.stylix.colors.withHashtag.base00;
        regular1 = config.lib.stylix.colors.withHashtag.base08;
        regular2 = config.lib.stylix.colors.withHashtag.base0B;
        regular3 = config.lib.stylix.colors.withHashtag.base0A;
        regular4 = config.lib.stylix.colors.withHashtag.base0D;
        regular5 = config.lib.stylix.colors.withHashtag.base0E;
        regular6 = config.lib.stylix.colors.withHashtag.base0C;
        regular7 = config.lib.stylix.colors.withHashtag.base05;
        bright0 = config.lib.stylix.colors.withHashtag.base03;
        bright1 = config.lib.stylix.colors.withHashtag.base09;
        bright2 = config.lib.stylix.colors.withHashtag.base0F;
        bright3 = config.lib.stylix.colors.withHashtag.base01;
        bright4 = config.lib.stylix.colors.withHashtag.base02;
        bright5 = config.lib.stylix.colors.withHashtag.base04;
        bright6 = config.lib.stylix.colors.withHashtag.base06;
        bright7 = config.lib.stylix.colors.withHashtag.base07;
      };
    };
  };
}
