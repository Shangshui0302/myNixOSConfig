{ config, pkgs, materialGnomeTheme, ... }:
{
  # GNOME 变体 home：共享 base + Material-Gnome 主题（GTK 应用部分抽在 theme-material.nix，与 Hyprland 共享）。
  imports = [
    ../../home/base.nix
    ../../home/theme-material.nix
  ];

  # GNOME 变体未接入 Darkman，保持原有固定深色偏好。
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
}
