{ pkgs, ... }:

{
  # System-level session integration shared by the Hyprland/niri DE.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  # HiDPI display scale for main DE sessions
  environment.sessionVariables = {
    GDK_SCALE = "2";
  };

  # Main DE Fcitx5 theme addons & classicui fallback configuration
  i18n.inputMethod.fcitx5 = {
    addons = with pkgs; [
      fcitx5-mellow-themes
      fcitx5-material-color
      catppuccin-fcitx5
    ];
    settings.addons.classicui.globalSection = {
      Theme = "mellow-matugen";
      DarkTheme = "mellow-matugen-dark";
      UseDarkTheme = "True";
      "Vertical Candidate List" = "True";
    };
  };

  # Expose niri's session entry to greetd; its actual user configuration stays in Home Manager.
  services.displayManager.sessionPackages = [ pkgs.niri ];

  # GUI privilege requests use polkit-1, independently of sudo or the lockscreen.
  # Face recognition may succeed on its own; failure continues to pam_unix.
  security.pam.services.polkit-1.howdy = {
    enable = true;
    control = "sufficient";
  };

  xdg.portal = {
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr pkgs.darkman ];

    config.hyprland = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.Settings" = [ "darkman" ];
    };

    config.niri = {
      default = [ "wlr" "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
      "org.freedesktop.impl.portal.Settings" = [ "darkman" ];
    };
  };
}
