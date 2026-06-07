{ ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  systemd.settings.Manager.DefaultsTimeoutStopSec = 15;

  fileSystems."/boot" = {
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  system.stateVersion = "25.11";
}
