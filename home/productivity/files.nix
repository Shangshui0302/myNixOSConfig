{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ouch p7zip unzip file-roller xarchiver
    nemo nemo-emblems nemo-fileroller nemo-preview
    
    # Dolphin & Preview thumbnailers
    kdePackages.dolphin
    kdePackages.kdegraphics-thumbnailers
    kdePackages.ffmpegthumbs
    kdePackages.kio-extras
    kdePackages.kimageformats
  ];

  xdg.desktopEntries.nemo = {
    name = "Nemo";
    icon = "nemo";
    exec = "nemo %F";
    type = "Application";
    categories = [ "System" "FileTools" "FileManager" "GTK" ];
    mimeType = [ "inode/directory" ];
    noDisplay = false;
  };
}
