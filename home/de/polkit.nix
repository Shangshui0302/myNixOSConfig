{ ... }:

{
  # The agent belongs to the graphical session, not either desktop shell.
  # shell-switcher can stop Noctalia/Caelestia without removing authentication UI.
  services.hyprpolkitagent.enable = true;

  systemd.user.services.hyprpolkitagent.Service = {
    Restart = "on-failure";
    RestartSec = 2;
    # Qtct supplies the live Matugen palette. Kvantum retains its startup palette,
    # so use Fusion for QApplication only; Qt Quick keeps org.hyprland.style.
    Environment = [
      "QT_QPA_PLATFORMTHEME=qt6ct"
      "QT_STYLE_OVERRIDE=Fusion"
    ];
  };
}
