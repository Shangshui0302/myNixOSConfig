{
  config,
  lib,
  pkgs,
  ...
}:

let
  # The application and its mutable data stay in Arch; HM owns only login startup.
  startTokenMonitor = pkgs.writeShellScript "token-monitor-distrobox-autostart" ''
    if ! ${pkgs.podman}/bin/podman container exists arch; then
      echo "Token Monitor autostart: the existing arch Distrobox is missing." >&2
      exit 1
    fi

    exec ${pkgs.distrobox}/bin/distrobox-enter --name arch --no-tty -- \
      /usr/bin/env CODEX_HOME=${lib.escapeShellArg "${config.home.homeDirectory}/.codex"} \
      /usr/bin/token-monitor --ozone-platform=wayland
  '';

  desktopEntry = pkgs.makeDesktopItem {
    name = "token-monitor-distrobox";
    desktopName = "Token Monitor";
    comment = "AI usage and quota monitor in the existing Arch Distrobox";
    exec = toString startTokenMonitor;
    terminal = false;
    startupNotify = false;
    categories = [ "Development" ];
  };
in
{
  home.packages = [ desktopEntry ];

  # UWSM, niri-session and GNOME provide the desktop autostart lifecycle.
  # Tray-only mode and the Hub configuration remain application settings.
  xdg.autostart = {
    enable = true;
    entries = [ "${desktopEntry}/share/applications/token-monitor-distrobox.desktop" ];
  };
}
