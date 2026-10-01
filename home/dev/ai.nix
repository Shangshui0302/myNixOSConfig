{ pkgs, inputs, ... }:

let
  codexDesktop = inputs.codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.codex-desktop;
in
{
  home.packages = with pkgs; [
    codex
    codexDesktop
    antigravity-cli
    antigravity-hub
  ];
}
