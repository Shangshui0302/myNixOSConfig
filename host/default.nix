{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  # main（Hyprland/niri DE）：共享 base + 桌面会话集成。
  # sops-nix / home-manager 模块在 flake.nix modules 中引入。
  imports = [
    ./base/default.nix
    ./de/sessions.nix
    ./de/greeter.nix
  ];

  # GNOME 变体：inheritParentConfig=false，完全不继承本配置（桌面包体不进 GNOME 闭包）。
  # 变体系统层在 host/gnome/、用户层在 home/gnome.nix，boot 菜单显示 "NixOS (gnome)"。
  specialisation.gnome = {
    inheritParentConfig = false;
    configuration = import ./gnome/default.nix;
  };
}
