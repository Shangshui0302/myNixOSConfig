{ pkgs, ... }:

{
  home.packages = with pkgs; [
    claude-code codex
    (import ../../local-deriv/officecli.nix { inherit pkgs; })
#   (import ../../local-deriv/aionui.nix { inherit pkgs; })
  ];
}
