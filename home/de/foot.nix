{ pkgs, ... }:

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
        foreground = "e0e2e8";
        background = "101418";
        selection-background = "34383d";
        selection-foreground = "f0f2f5";
        cursor = "101418 e0e2e8";
        regular0 = "101418";
        regular1 = "ff3270";
        regular2 = "42f558";
        regular3 = "fff332";
        regular4 = "1c8de8";
        regular5 = "003e71";
        regular6 = "42a5f5";
        regular7 = "e8f4ff";
        bright0 = "8d979f";
        bright1 = "ff739e";
        bright2 = "7cff8d";
        bright3 = "fff77c";
        bright4 = "60b8ff";
        bright5 = "7cc4ff";
        bright6 = "abd9ff";
        bright7 = "f5faff";
        dim-blend-towards = "black";
      };
    };
  };
}
