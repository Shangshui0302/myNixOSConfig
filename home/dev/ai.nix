{ pkgs, inputs, ... }:

let
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  codexDesktop = inputs.codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.codex-desktop;
  ccSwitch = import ../../local-deriv/cc-switch.nix { inherit pkgs; };
in
{
  home.packages = with pkgs; [
    codex
    llmAgents.officecli
    ccSwitch
    codexDesktop
    codebase-memory-mcp
  ];
}
