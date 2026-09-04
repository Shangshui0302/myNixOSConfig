{ pkgs, ... }:

{
  home.packages = with pkgs; [
    libreoffice-stable
    onlyoffice-desktopeditors
    obsidian
    typora
    zettlr
    kdePackages.ghostwriter
  ];
}
