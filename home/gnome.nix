{
  config,
  pkgs,
  materialGnomeTheme,
  ...
}:
{
  # GNOME 变体 home（入口）：共享 base + 静态 Material-Gnome（theme/gtk-static.nix）。
  # 主 DE 的 matugen 运行时主题（theme/gtk-matugen.nix）不进 GNOME 变体。
  imports = [
    ./base.nix
    ./theme/gtk-static.nix
  ];

  # GNOME 变体未接入 Darkman，保持原有固定深色偏好。
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
}
