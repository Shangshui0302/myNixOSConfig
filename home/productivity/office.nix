{ lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    libreoffice-stable
    onlyoffice-desktopeditors
    obsidian typora zettlr kdePackages.ghostwriter
  ];

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
