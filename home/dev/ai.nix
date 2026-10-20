{ pkgs, inputs, ... }:

let
  codexDesktop = inputs.codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.codex-desktop;
  agentReach = pkgs.callPackage ../../local-deriv/agent-reach.nix { };
  opencli = pkgs.callPackage ../../local-deriv/opencli.nix { };
in
{
  imports = [ ./orca.nix ];

  home.packages = with pkgs; [
    codex
    codexDesktop
    antigravity-cli
    antigravity-hub
    agentReach
    opencli
    mcporter
  ];

  programs.yt-dlp.enable = true;

  # Keep the local workflow declarative; upstream's installer also installs tools
  # and registers a broader skill. Exa and credential files are intentionally absent.
  home.file.".agents/skills/agent-reach/SKILL.md".source = ./agent-reach/SKILL.md;
}
