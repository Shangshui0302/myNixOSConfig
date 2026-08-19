{ config, lib, pkgs, ... }:
{
  # 共享系统基础：被 main（Hyprland）与 specialisation/gnome 变体共同 import。
  imports = [
    ../../hardware-configuration.nix
    ./boot.nix
    ./hardware.nix
    ./compat.nix
    ./locale.nix
    ./nix.nix
    ./users.nix
    ./network.nix
    ./services.nix
    ./desktop.nix
    ./gaming.nix
    ./containers.nix
    ./sops.nix
  ];
}
