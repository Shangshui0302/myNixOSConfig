{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gthumb
    gimp
  ];
}
