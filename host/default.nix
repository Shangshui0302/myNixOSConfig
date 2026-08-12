{ config, lib, pkgs, inputs, ... }:
{
  # main（Hyprland 主桌面）：共享 base + Hyprland 特有。
  # sops-nix / home-manager 模块在 flake.nix modules 中引入。
  imports = [
    ./base/default.nix
    ./hyprland/desktop.nix
    ./hyprland/greeter.nix
  ];

  # GNOME 变体：inheritParentConfig=false，完全不继承本配置（Hyprland 包体不进 GNOME 闭包）。
  # 变体全部代码在 specialisation/gnome/，boot 菜单显示 "NixOS (gnome)"。
  specialisation.gnome = {
    inheritParentConfig = false;
    configuration = import ../specialisation/gnome/default.nix;
  };
}
