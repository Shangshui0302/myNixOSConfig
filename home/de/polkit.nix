{ ... }:

{
  # The agent belongs to the graphical session, not either desktop shell.
  # shell-switcher can stop Noctalia/Caelestia without removing authentication UI.
  services.hyprpolkitagent.enable = true;

  systemd.user.services.hyprpolkitagent.Service = {
    Restart = "on-failure";
    RestartSec = 2;
    # Qt Widgets 使用共享 WhiteSur/Kvantum；Qt Quick 保留 Hyprland 样式。
    Environment = [
      "QT_QPA_PLATFORMTHEME=qt6ct"
      "QT_STYLE_OVERRIDE=kvantum"
    ];
  };
}
