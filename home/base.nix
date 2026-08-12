{ config, pkgs, inputs, ... }:

{
  # 共享 home 入口：两 DE（main Hyprland 与 specialisation/gnome）共同 import。
  imports = [
    ./git.nix
    ./theme-base.nix
    ./env
    ./dev
    ./productivity
    ./leisure
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  home.username = "lishangshui";
  home.homeDirectory = "/home/lishangshui";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
