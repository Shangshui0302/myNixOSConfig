{ pkgs, ... }:

{
  home.packages = with pkgs; [
    loupe mpv ffmpegthumbnailer tumbler
    netease-cloud-music-gtk obs-studio go-musicfox
    yesplaymusic netease-cloud-music-web-player
  ];
}
