{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ouch p7zip unzip file-roller xarchiver
    nautilus sushi
    
    # Dolphin & Preview thumbnailers
    kdePackages.dolphin
    kdePackages.kdegraphics-thumbnailers
    kdePackages.ffmpegthumbs
    kdePackages.kio-extras
    kdePackages.kimageformats
  ];


}
