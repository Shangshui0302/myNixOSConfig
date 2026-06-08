{ pkgs, ... }:

{
  home.packages = with pkgs; [
    loupe mpv ffmpegthumbnailer tumbler
    netease-cloud-music-gtk obs-studio go-musicfox
    open-orpheus yesplaymusic netease-cloud-music-web-player
  ];
}
