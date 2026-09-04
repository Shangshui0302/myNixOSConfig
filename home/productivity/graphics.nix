{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gthumb
    gimp
    ffmpeg
    kdePackages.kdenlive
    glaxnimate
    blender
  ];
}
