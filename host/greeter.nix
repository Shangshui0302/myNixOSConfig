{ pkgs, ... }:

{
  # No display manager — pure TTY login.
  # TTY1 login → howdy face unlock → shell → uwsm start <compositor>.
  # GNOME is isolated to a specialisation variant (with GDM).
  services.displayManager.sddm.enable = false;
  services.xserver.displayManager.lightdm.enable = false;
  services.greetd.enable = false;
}
