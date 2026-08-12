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
        font = "Anthropic Mono Variable:size=12, Source Han Sans SC:size=12";
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
      "colors-dark" = {
        alpha = "0.8";
        blur = "yes";
        background = "0e1019";
        foreground = "fffaf4";
        regular0  = "666666";
        regular1  = "ff000f";
        regular2  = "8ce10b";
        regular3  = "ffb900";
        regular4  = "008df8";
        regular5  = "6d43a6";
        regular6  = "00d8eb";
        regular7  = "ffffff";
        bright0   = "888888";
        bright1   = "ff2740";
        bright2   = "abe15b";
        bright3   = "ffd242";
        bright4   = "0092ff";
        bright5   = "9a5feb";
        bright6   = "67fff0";
        bright7   = "ffffff";
      };
    };
  };
}
