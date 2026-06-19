{ pkgs, ... }:

{
  home.packages = with pkgs; [
    loupe mpv ffmpegthumbnailer tumbler
    netease-cloud-music-gtk obs-studio go-musicfox
    (import ../../local-deriv/yesplaymusic.nix { inherit pkgs; })
    (import ../../local-deriv/netease-cloud-music-web-player.nix { inherit pkgs; })
    (import ../../local-deriv/animeko.nix { inherit pkgs; })
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
