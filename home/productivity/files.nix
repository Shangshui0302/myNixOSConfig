{ ... }:

{
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
