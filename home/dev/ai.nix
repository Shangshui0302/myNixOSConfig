{ pkgs, ... }:

{
  home.packages = with pkgs; [
    claude-code codex gemini-cli
    (import ../../pkgs/officecli.nix { inherit pkgs; })
    (import ../../pkgs/aionui.nix { inherit pkgs; })
  ];
}
