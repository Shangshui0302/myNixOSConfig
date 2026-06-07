{ config, pkgs, inputs, ... }:

{
  imports = [
    ./packages.nix
    ./git.nix
    ./theme.nix
    ./env
    ./dev
    ./productivity
    ./media
  ];

  home.username = "lishangshui";
  home.homeDirectory = "/home/lishangshui";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
