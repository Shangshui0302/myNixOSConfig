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
      # 配色：背景/前景来自 stylix（config.lib.stylix.colors 壁纸取色，与合成器边框同源）；
      # 语法高亮 8 色用经典高对比 palette——壁纸（金色系）取出的 base08-0F 区分度差，
      # 完全分不清语法重点。foot 1.27 颜色不接受 # 前缀，全部用无前缀 hex。
      # blur 是 foot 特效（stylix 不碰）单独保留
      "colors-dark" = {
        blur = "yes";
        alpha = "0.8";
        background = config.lib.stylix.colors.base00;
        foreground = config.lib.stylix.colors.base05;
        regular0 = config.lib.stylix.colors.base00; # 黑（同背景）
        regular1 = "ff000f"; # 红
        regular2 = "8ce10b"; # 绿
        regular3 = "ffb900"; # 黄
        regular4 = "008df8"; # 蓝
        regular5 = "6d43a6"; # 紫
        regular6 = "00d8eb"; # 青
        regular7 = config.lib.stylix.colors.base05; # 白/前景
        bright0 = "888888";
        bright1 = "ff2740";
        bright2 = "abe15b";
        bright3 = "ffd242";
        bright4 = "0092ff";
        bright5 = "9a5feb";
        bright6 = "67fff0";
        bright7 = "ffffff";
      };
    };
  };
}
