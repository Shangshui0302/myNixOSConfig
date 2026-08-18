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
  programs.foot = {
    enable = true;
    server.enable = true;
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
        blur = "yes";
        alpha = "0.8";
        background = config.lib.stylix.colors.base00;
        foreground = config.lib.stylix.colors.base05;
        regular0 = config.lib.stylix.colors.base00;
        regular1 = "ff000f";
        regular2 = "8ce10b";
        regular3 = "ffb900";
        regular4 = "008df8";
        regular5 = "6d43a6";
        regular6 = "00d8eb";
        regular7 = config.lib.stylix.colors.base05;
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
