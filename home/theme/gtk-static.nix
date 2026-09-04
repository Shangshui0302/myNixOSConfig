{ pkgs, materialGnomeTheme, ... }:
{
  # 静态 Material-Gnome GTK 主题：仅 GNOME 变体使用（固定深色，不接 Darkman/matugen）。
  # 主 DE 用 gtk-matugen.nix（运行时取色）；若未来变体需要差异化 GTK 主题再拆。

  # GTK3 主题
  dconf.settings."org/gnome/desktop/interface".gtk-theme = "Material-Gnome";

  # GTK4/Libadwaita 应用：Libadwaita 不读 ~/.themes，需 ~/.config/gtk-4.0/gtk.css 覆盖
  home.file.".config/gtk-4.0/gtk.css".source =
    "${materialGnomeTheme}/share/themes/Material-Gnome/gtk-4.0/gtk.css";
  home.file.".config/gtk-4.0/gtk-dark.css".source =
    "${materialGnomeTheme}/share/themes/Material-Gnome/gtk-4.0/gtk-dark.css";
  home.file.".config/gtk-4.0/colors.css".source =
    "${materialGnomeTheme}/share/themes/Material-Gnome/gtk-4.0/colors.css";

  # 主题源 ~/.themes（GTK3 应用 / flatpak 访问）
  home.file.".themes/Material-Gnome".source = "${materialGnomeTheme}/share/themes/Material-Gnome";

  # Flatpak 沙箱跟随（读 ~/.themes + GTK_THEME）
  services.flatpak.overrides.settings = {
    global = {
      Context.filesystems = "$HOME/.themes:ro";
      Environment.GTK_THEME = "Material-Gnome";
    };
  };
}
