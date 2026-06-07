{ config, pkgs, inputs, ... }:

{
  imports = [
    ./packages.nix
    ./theme.nix
    ./git.nix
    ./shell.nix
    ./hyprland.nix
    ./nvim.nix
    ./yazi.nix
    ./btop.nix
    ./noctalia.nix
    ./onedrive.nix
    ./apps-dev.nix
    ./apps-comms.nix
    ./apps-office.nix
    ./apps-media.nix
    ./apps-files.nix
  ];

  home.username = "lishangshui";
  home.homeDirectory = "/home/lishangshui";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
