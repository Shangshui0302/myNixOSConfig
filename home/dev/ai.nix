{ pkgs, inputs, ... }:

let
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  codexDesktop = inputs.codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.codex-desktop;
in
{
  home.packages = with pkgs; [
    codex
    llmAgents.officecli
    cc-switch
    codexDesktop
    codebase-memory-mcp
    (import ../../local-deriv/rtk.nix { inherit pkgs; })
  ];
}
