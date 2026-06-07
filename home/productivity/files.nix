{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ouch p7zip unzip file-roller xarchiver
    nemo nemo-emblems nemo-fileroller
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
