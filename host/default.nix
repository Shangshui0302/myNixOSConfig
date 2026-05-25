{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ../hardware-configuration.nix
    ./core.nix
    ./desktop.nix
    ./services.nix
    ./packages.nix
    ./litellm.nix
  ];
}
