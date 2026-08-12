{ config, pkgs, ... }:
{
  # main（Hyprland）home 入口：共享 base + Hyprland 特有主题与合成器组。
  imports = [
    ./base.nix
    ./theme-hyprland.nix
    ./hyprland
  ];
}
