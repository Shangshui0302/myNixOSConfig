{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ouch p7zip unzip file-roller
    nautilus sushi
    kdePackages.dolphin
  ];


}
