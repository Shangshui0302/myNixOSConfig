{ config, pkgs, ... }:

{
  home.packages = [ pkgs.kdePackages.polkit-kde-agent-1 ];

  # Home Manager has no KDE polkit-agent module. Keep the upstream unit name
  # and service settings, but bind startup to the Hyprland/niri session target.
  # The package's XDG autostart is KDE-only and marked X-systemd-skip=true.
  systemd.user.services.plasma-polkit-agent = {
    Unit = {
      Description = "KDE PolicyKit Authentication Agent";
      PartOf = [ config.wayland.systemd.target ];
      After = [ config.wayland.systemd.target ];
    };
    Service = {
      ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
      # Qt gives QT_STYLE_OVERRIDE precedence over QT_QUICK_CONTROLS_STYLE.
      # Kvantum is not a Quick module; qtct still selects it for QWidget styling.
      UnsetEnvironment = [ "QT_STYLE_OVERRIDE" ];
      Environment = [ "QT_QUICK_CONTROLS_STYLE=org.kde.desktop" ];
      BusName = "org.kde.polkit-kde-authentication-agent-1";
      Slice = "background.slice";
      TimeoutStopSec = 5;
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ config.wayland.systemd.target ];
  };
}
