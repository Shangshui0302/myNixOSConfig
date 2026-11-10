{ pkgs, ... }:

{
  programs.direnv.enable = true;

  home.packages = with pkgs; [
    nodejs_24
    gcc
    tree
    gh
    tree-sitter
    ripgrep
    python3
    sops

    # Language servers consumed by DSH's LSP plugins (dsh-lsp-stdio and
    # dsh-lsp-actions resolve them by bare command name from PATH). They used
    # are also available in the Arch container; these provide host equivalents
    # for DSH-X if the native launcher is used.
    bash-language-server
    clang-tools # clangd
    gopls
    lua-language-server
    nixd
    pyright
    rust-analyzer
    taplo
    typescript-language-server
    vscode-json-languageserver
    yaml-language-server
  ];
}
