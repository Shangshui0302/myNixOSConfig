{ pkgs, ... }:

{
  home.packages = with pkgs; [
    libreoffice-stable
    obsidian
    typora
    zettlr
    kdePackages.ghostwriter
    zotero
    (pkgs.callPackage ../../local-deriv/agentero.nix { })
  ];
}
