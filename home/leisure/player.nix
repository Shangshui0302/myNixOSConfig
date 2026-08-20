{ pkgs, ... }:

let
  animeko = import ../../local-deriv/animeko.nix { inherit pkgs; };
in
{
  home.packages = with pkgs; [
    loupe mpv
    obs-studio
    (import ../../local-deriv/netease-cloud-music-web-player.nix { inherit pkgs; })
    animeko
  ];

  xdg.dataFile."icons/hicolor/1024x1024/apps/animeko.png".source =
    "${animeko.passthru.extracted}/usr/lib/Ani.png";

  xdg.desktopEntries.animeko = {
    name = "Animeko";
    comment = "集找番、追番、看番的一站式弹幕追番平台";
    exec = "animeko";
    icon = "animeko";
    terminal = false;
    categories = [ "AudioVideo" "Player" "Video" ];
  };
}
