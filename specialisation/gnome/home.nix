{ config, pkgs, materialGnomeTheme, ... }:
{
  # GNOME 变体 home：共享 base + Material-Gnome 主题应用（仅此变体；Hyprland 主桌面在 theme-hyprland.nix 用 adw）。
  imports = [
    ../../home/base.nix
  ];

  # GTK3 主题
  dconf.settings."org/gnome/desktop/interface".gtk-theme = "Material-Gnome";

  # GTK4/Libadwaita 应用：Libadwaita 不读 ~/.themes，需 ~/.config/gtk-4.0/gtk.css 覆盖
  home.file.".config/gtk-4.0/gtk.css".source =
    "${materialGnomeTheme}/share/themes/Material-Gnome/gtk-4.0/gtk.css";
  home.file.".config/gtk-4.0/gtk-dark.css".source =
    "${materialGnomeTheme}/share/themes/Material-Gnome/gtk-4.0/gtk-dark.css";
  home.file.".config/gtk-4.0/colors.css".source =
    "${materialGnomeTheme}/share/themes/Material-Gnome/gtk-4.0/colors.css";

  # 主题源 ~/.themes（user-themes / GTK3 / flatpak 访问）
  home.file.".themes/Material-Gnome".source =
    "${materialGnomeTheme}/share/themes/Material-Gnome";

  # Flatpak 沙箱跟随（读 ~/.themes + GTK_THEME）。
  # 注意：override 文件持久，切回主系统 rebuild 不会自动清除。
  services.flatpak.overrides.settings = {
    global = {
      Context.filesystems = "$HOME/.themes:ro";
      Environment.GTK_THEME = "Material-Gnome";
    };
  };
}
