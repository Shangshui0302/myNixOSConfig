{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ouch p7zip unzip file-roller xarchiver
    (nemo-with-extensions.override { 
      extensions = [ 
        nemo-fileroller 
        (nemo-preview.overrideAttrs (old: {
          gappsWrapperArgs = (old.gappsWrapperArgs or []) ++ [
            "--set" "GDK_BACKEND" "x11"
            "--set" "CLUTTER_BACKEND" "x11"
          ];
        }))
        nemo-emblems 
      ]; 
    })
    
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
