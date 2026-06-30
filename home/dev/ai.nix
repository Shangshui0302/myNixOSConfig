{ pkgs, ... }:

{
  home.packages = with pkgs; [
    claude-code codex
    (import ../../local-deriv/officecli.nix { inherit pkgs; })
    antigravity pkgs.antigravity-cli
  ];
}
