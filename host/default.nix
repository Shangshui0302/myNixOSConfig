{ config, lib, pkgs, inputs, ... }:
{
  # main（Hyprland/niri DE）：共享 base + 桌面会话集成。
  # sops-nix / home-manager 模块在 flake.nix modules 中引入。
  imports = [
    ./base/default.nix
    ./de/sessions.nix
    ./de/greeter.nix
  ];

  # GNOME 变体：inheritParentConfig=false，完全不继承本配置（桌面包体不进 GNOME 闭包）。
  # 变体全部代码在 specialisation/gnome/，boot 菜单显示 "NixOS (gnome)"。
  specialisation.gnome = {
    inheritParentConfig = false;
    configuration = import ../specialisation/gnome/default.nix;
  };
}
