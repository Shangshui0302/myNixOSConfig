{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ../hardware-configuration.nix
    ./boot.nix
    ./hardware.nix
    ./locale.nix
    ./nix.nix
    ./users.nix
    ./network.nix
    ./services.nix
    ./desktop.nix
    ./sddm.nix
    ./litellm.nix
    ./gaming.nix
  ];
}
