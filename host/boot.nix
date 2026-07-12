{ ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  systemd.settings.Manager.DefaultsTimeoutStopSec = 15;

  # /boot options intentionally override hardware-configuration.nix
  # (fmask/dmask 0077 vs auto-generated 0022) for stricter EFI permissions.
  # device is inherited from hardware-configuration.nix via merge.
  fileSystems."/boot" = {
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  boot.kernelModules = [ "ntfs3" ];

  system.stateVersion = "25.11";
}
