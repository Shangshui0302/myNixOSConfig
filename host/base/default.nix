{
  config,
  lib,
  pkgs,
  ...
}:
{
  # 共享系统基础：被 main（Hyprland）与 host/gnome 变体共同 import。
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
    ./virtualization.nix
    ./containers.nix
    ./sops.nix
  ];

  # 暴露系统包的 Fish vendor 补全，并生成系统命令的 manpage 补全。
  programs.fish.enable = true;
}
