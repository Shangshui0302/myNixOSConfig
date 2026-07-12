{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ouch p7zip unzip file-roller xarchiver
    nautilus sushi
    kdePackages.dolphin
  ];


}
