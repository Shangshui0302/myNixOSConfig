{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    libreoffice-fresh
    onlyoffice-desktopeditors
    obsidian typora zettlr kdePackages.ghostwriter
  ];

/*   xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"       = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [ "onlyoffice-desktopeditors.desktop" ];
      "application/msword"                                                       = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.ms-excel"                                                 = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.ms-powerpoint"                                            = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.oasis.opendocument.text"                                  = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.oasis.opendocument.spreadsheet"                           = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.oasis.opendocument.presentation"                          = [ "onlyoffice-desktopeditors.desktop" ];
    };
  }; */

  home.activation = {
    copyMsCjkFonts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      out="$HOME/.local/share/fonts/MS"
      rm -rf "$out"
      mkdir -p "$out"
      find /persist/Fonts/ -type f \( -name "*.ttf" -o -name "*.ttc" \) -exec cp -L {} "$out/" \;
      chmod 644 "$out"/*
      ${pkgs.fontconfig}/bin/fc-cache -f "$out" >/dev/null 2>&1 || true
    '';
  };
}
