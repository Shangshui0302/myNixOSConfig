{ pkgs, ... }:

{
  # niri — scrollable-tiling Wayland compositor
  # uwsm 通过 wayland-sessions/niri.desktop 自动发现
  home.packages = [ pkgs.niri ];
}
