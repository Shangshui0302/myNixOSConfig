{ pkgs, ... }:

{
  home.packages = with pkgs; [
    loupe mpv
    obs-studio
    (import ../../local-deriv/netease-cloud-music-web-player.nix { inherit pkgs; })
    (import ../../local-deriv/animeko.nix { inherit pkgs; })
  ];
}
