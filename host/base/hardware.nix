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

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc stdenv.cc.cc.lib zlib glib libGL freetype
    libX11 fontconfig fuse3 icu nss openssl curl expat libgcc
  ];
}
