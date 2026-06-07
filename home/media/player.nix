{ pkgs, ... }:

{
  home.packages = with pkgs; [
    netease-cloud-music-gtk obs-studio go-musicfox
  ];
}
