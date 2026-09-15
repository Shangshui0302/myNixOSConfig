{ pkgs, ... }:

let
  modernz = pkgs.callPackage ../../local-deriv/modernz.nix { };
in
{
  home.packages = with pkgs; [
    loupe
    mpv
    ani-cli
    kazumi
    obs-studio
    (import ../../local-deriv/netease-cloud-music-web-player.nix { inherit pkgs; })
    go-musicfox
  ];

  xdg.configFile."mpv/mpv.conf".text = ''
    osc=no
    border=no
    title-bar=no
  '';

  home.file.".config/mpv/scripts/modernz.lua".source = "${modernz}/share/mpv/scripts/modernz.lua";
  home.file.".config/mpv/fonts/modernz-icons.ttf".source = "${modernz}/share/fonts/modernz-icons.ttf";
  home.file.".config/mpv/script-opts/modernz-locale.json".source =
    "${modernz}/share/mpv/script-opts/modernz-locale.json";

  xdg.desktopEntries.musicfox = {
    name = "go-musicfox";
    genericName = "Terminal Music Player";
    comment = "网易云音乐命令行客户端";
    exec = "foot -e musicfox";
    icon = "terminal";
    terminal = false;
    categories = [
      "AudioVideo"
      "Audio"
      "Player"
    ];
  };
}
