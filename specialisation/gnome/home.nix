{ config, pkgs, materialGnomeTheme, ... }:
{
  # GNOME 变体 home：共享 base + Material-Gnome 主题（GTK 应用部分抽在 theme-material.nix，与 Hyprland 共享）。
  imports = [
    ../../home/base.nix
    ../../home/theme-material.nix
  ];
}
