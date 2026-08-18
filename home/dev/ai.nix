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

  # 禁用 cc-switch 的 XDG autostart，按需手动运行 cc-switch
  xdg.configFile."autostart/CC Switch.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';
  
}
