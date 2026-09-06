{ pkgs, inputs, ... }:

let
  codexDesktop = inputs.codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.codex-desktop;
  ccSwitch = import ../../local-deriv/cc-switch.nix { inherit pkgs; };
in
{
  home.packages = with pkgs; [
    codex
    ccSwitch
    codexDesktop
    codebase-memory-mcp
  ];
}
