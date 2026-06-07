{ pkgs, ... }:

{
  home.packages = with pkgs; [
    firefox google-chrome
    netease-cloud-music-gtk obs-studio go-musicfox
  ];
}
