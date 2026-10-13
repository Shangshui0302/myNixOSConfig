{ pkgs, ... }:

{
  # System-level session integration shared by the Hyprland/niri DE.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
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
