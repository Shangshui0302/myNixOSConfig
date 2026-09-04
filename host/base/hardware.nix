{ pkgs, ... }:

let
  kernelPackages = pkgs.linuxPackages.extend (
    _final: prev: {
      tuxedo-drivers = prev.tuxedo-drivers.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./tuxedo-mechrevo.patch ];
      });
    }
  );
in

{
  boot.kernelPackages = kernelPackages;
  boot.extraModulePackages = [ kernelPackages.acpi_call ];
  boot.kernelModules = [ "acpi_call" ];
  hardware.tuxedo-drivers.enable = true;

  boot.initrd.kernelModules = [ "amdgpu" ];
  services.xserver.videoDrivers = [ "amdgpu" ];

  # 共享图形栈（原在 gaming.nix，属硬件能力而非娱乐域）
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  services.udev.packages = [
    pkgs.stlink
    pkgs.openocd
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="tty", KERNEL=="ttyUSB[0-9]*", GROUP="dialout", MODE="0660"
    SUBSYSTEM=="tty", KERNEL=="ttyACM[0-9]*", GROUP="dialout", MODE="0660"
  '';

}
