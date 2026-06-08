{ pkgs, ... }:

{
  home.packages = with pkgs; [
    loupe mpv ffmpegthumbnailer tumbler
    netease-cloud-music-gtk obs-studio go-musicfox
    yesplaymusic netease-cloud-music-web-player
  ];

  xdg.desktopEntries.musicfox = {
    name = "go-musicfox";
    genericName = "Terminal Music Player";
    comment = "网易云音乐命令行客户端";
    exec = "foot -e musicfox";
    icon = "terminal";
    terminal = false;
    categories = [ "AudioVideo" "Audio" "Player" ];
  };
}
