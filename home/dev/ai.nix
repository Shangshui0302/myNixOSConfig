{ pkgs, inputs, ... }:

let
  codexDesktop = inputs.codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.codex-desktop;
  agentReach = pkgs.callPackage ../../local-deriv/agent-reach.nix { };
  opencli = pkgs.callPackage ../../local-deriv/opencli.nix { };
in
{
  imports = [
    ./agent-orchestrator.nix
  ];

  home.packages = with pkgs; [
    codex
    codexDesktop
    github-copilot-cli
    kiro
    kiro-cli
    code-cursor
    cursor-cli
    grok-build
    paseo
    paseo.desktop
    herdr
    (pkgs.callPackage ../../local-deriv/kirocrew.nix { })
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.grok-bot
    antigravity-cli
    antigravity-hub
    agentReach
    opencli
    mcporter
  ];

  # Start the desktop app once the graphical session processes XDG autostart.
  xdg.autostart = {
    enable = true;
    entries = [ "${codexDesktop}/share/applications/codex-desktop.desktop" ];
  };

  programs.yt-dlp.enable = true;

  # Keep the local workflow declarative; upstream's installer also installs tools
  # and registers a broader skill. Exa and credential files are intentionally absent.
  home.file.".agents/skills/agent-reach/SKILL.md".source = ./agent-reach/SKILL.md;
}
