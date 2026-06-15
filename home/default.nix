{ config, pkgs, inputs, ... }:

{
  imports = [
    ./git.nix
    ./theme.nix
    ./env
    ./dev
    ./productivity
    ./leisure
  ];

  home.username = "lishangshui";
  home.homeDirectory = "/home/lishangshui";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
