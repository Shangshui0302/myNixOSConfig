{ pkgs, ... }:

{
  programs.direnv.enable = true;

  home.packages = with pkgs; [
    nodejs_24 gcc tree gh tree-sitter ripgrep python3
  ];
}
