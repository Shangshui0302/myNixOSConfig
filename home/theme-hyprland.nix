{ pkgs, materialGnomeTheme, ... }:
{
  # Hyprland 主桌面 Qt 主题 + GTK Material-Gnome（GTK 应用部分抽在 theme-material.nix，与 GNOME 共享）。
  imports = [
    ./theme-material.nix
  ];

  home.packages = with pkgs; [
    libsForQt5.qt5ct
    kdePackages.breeze
    kdePackages.breeze-icons
    # GTK portal .portal file has UseIn=gnome, which blocks it on Hyprland.
    # Provide our own .portal file with Hyprland added so the Settings
    # interface (used by fcitx5 for dark/light theme) gets registered.
    (pkgs.runCommand "gtk-portal-hyprland" { } ''
      mkdir -p $out/share/xdg-desktop-portal/portals
      cat > $out/share/xdg-desktop-portal/portals/gtk.portal << 'PORTALEOF'
[portal]
DBusName=org.freedesktop.impl.portal.desktop.gtk
Interfaces=org.freedesktop.impl.portal.FileChooser;org.freedesktop.impl.portal.AppChooser;org.freedesktop.impl.portal.Print;org.freedesktop.impl.portal.Notification;org.freedesktop.impl.portal.Inhibit;org.freedesktop.impl.portal.Access;org.freedesktop.impl.portal.Account;org.freedesktop.impl.portal.Email;org.freedesktop.impl.portal.DynamicLauncher;org.freedesktop.impl.portal.Lockdown;org.freedesktop.impl.portal.Settings;org.freedesktop.impl.portal.Wallpaper;
UseIn=gnome;Hyprland
PORTALEOF
    '')
  ];

  # Hyprland 主桌面 dconf：GTK 主题 Material-Gnome + 深色偏好
  dconf.settings."org/gnome/desktop/interface" = {
    gtk-application-prefer-dark-theme = true;
  };
}
