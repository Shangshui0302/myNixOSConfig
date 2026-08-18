{ pkgs, ... }:
{
  # go-musicfox：网易云命令行播放器（desktop entry 依赖 foot 终端，仅主桌面 Hyprland）
  home.packages = [ pkgs.go-musicfox ];

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
