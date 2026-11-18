{ pkgs, pkgsLatest, ... }:

{
  home.packages = with pkgs; [
    libreoffice-stable
    obsidian
    typora
    zettlr
    kdePackages.ghostwriter
    zotero
    (pkgsLatest.callPackage ../../local-deriv/agentero.nix { })
  ];
}
