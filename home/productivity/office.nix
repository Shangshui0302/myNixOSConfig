{ pkgs, ... }:

{
  home.packages = with pkgs; [
    libreoffice-stable
    obsidian
    typora
    zettlr
    kdePackages.ghostwriter
    z-library-desktop
    zotero
    (pkgs.callPackage ../../local-deriv/agentero.nix { })
  ];
}
