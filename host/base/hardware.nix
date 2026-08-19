{ pkgs, ... }:

{
  boot.initrd.kernelModules = [ "amdgpu" ];
  services.xserver.videoDrivers = [ "amdgpu" ];

  services.udev.packages = [
    pkgs.stlink
    pkgs.openocd
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="tty", KERNEL=="ttyUSB[0-9]*", GROUP="dialout", MODE="0660"
    SUBSYSTEM=="tty", KERNEL=="ttyACM[0-9]*", GROUP="dialout", MODE="0660"
  '';

}
