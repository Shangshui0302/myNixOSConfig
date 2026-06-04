{ config, lib, pkgs, ... }:

{
  ####################################
  #
  # Boot & Kernel
  #
  ####################################

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  systemd.settings.Manager = {
    DefaultsTimeoutStopSec = 15;
  };

  # /boot security setting
  fileSystems."/boot" = {
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  ####################################
  #
  # Network
  #
  ####################################

  networking.hostName = "MechRevo-NixOS";
  networking.networkmanager.enable = true;

  ####################################
  #
  # Locale & Time
  #
  ####################################

  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "zh_CN.UTF-8";
  console = {
    font = "latarcyrheb-sun32";
    keyMap = "us";
  };

  ####################################
  #
  # Nix Configuration
  #
  ####################################

  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  ####################################
  #
  # Users
  #
  ####################################

  users.users.lishangshui = {
    isNormalUser = true;
    description = "Li Shangshui";
    extraGroups = [ "wheel" "networkmanager" "video" ];
  };

  security.sudo.extraRules = [
    {
      users = [ "lishangshui" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/nix";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/tee";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/chmod";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/chown";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/install";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/mv";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/cp";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/rm";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  system.stateVersion = "25.11";
}
