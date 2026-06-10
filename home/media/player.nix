{ pkgs, ... }:

{
  home.packages = with pkgs; [
    loupe mpv ffmpegthumbnailer tumbler
    netease-cloud-music-gtk obs-studio go-musicfox
    (import ../../pkgs/yesplaymusic.nix { inherit pkgs; })
    (import ../../pkgs/netease-cloud-music-web-player.nix { inherit pkgs; src = ../../assets/netease-cloud-music-web-player-1.6.0.tar.gz; })
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
