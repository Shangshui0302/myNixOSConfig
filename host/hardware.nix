{ pkgs, ... }:

{
  boot.initrd.kernelModules = [ "amdgpu" ];
  services.xserver.videoDrivers = [ "amdgpu" ];

  services.udev.packages = [
    pkgs.stlink
    pkgs.openocd
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc stdenv.cc.cc.lib zlib glib libGL freetype
    libX11 fontconfig fuse3 icu nss openssl curl expat libgcc
  ];
}
