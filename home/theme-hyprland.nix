{ pkgs, materialGnomeTheme, ... }:
{
  # Hyprland 主桌面 GTK/Qt 主题。
  # GTK 主题与 GNOME 变体统一为 Material-Gnome（同一壁纸 matugen 取色），
  # 但路径分开（本文件 vs specialisation/gnome/home.nix），方便之后差异化。

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

  # GTK3 主题（统一 Material-Gnome）
  dconf.settings."org/gnome/desktop/interface" = {
    gtk-theme = "Material-Gnome";
    gtk-application-prefer-dark-theme = true;
  };

  # GTK4/Libadwaita 应用：Libadwaita 不读 ~/.themes，需 ~/.config/gtk-4.0/gtk.css 覆盖
  home.file.".config/gtk-4.0/gtk.css".source =
    "${materialGnomeTheme}/share/themes/Material-Gnome/gtk-4.0/gtk.css";
  home.file.".config/gtk-4.0/gtk-dark.css".source =
    "${materialGnomeTheme}/share/themes/Material-Gnome/gtk-4.0/gtk-dark.css";
  home.file.".config/gtk-4.0/colors.css".source =
    "${materialGnomeTheme}/share/themes/Material-Gnome/gtk-4.0/colors.css";

  # 主题源 ~/.themes（GTK3 应用 / flatpak 访问）
  home.file.".themes/Material-Gnome".source =
    "${materialGnomeTheme}/share/themes/Material-Gnome";

  # Flatpak 沙箱跟随（读 ~/.themes + GTK_THEME）
  services.flatpak.overrides.settings = {
    global = {
      Context.filesystems = "$HOME/.themes:ro";
      Environment.GTK_THEME = "Material-Gnome";
    };
  };
}
