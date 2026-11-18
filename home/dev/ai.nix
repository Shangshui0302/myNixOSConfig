{
  config,
  pkgs,
  pkgsLatest,
  inputs,
  ...
}:

let
  codexDesktop =
    inputs.codex-desktop-linux.packages.${pkgsLatest.stdenv.hostPlatform.system}.codex-desktop;
  agentReach = pkgsLatest.callPackage ../../local-deriv/agent-reach.nix { };
  opencli = pkgsLatest.callPackage ../../local-deriv/opencli.nix { };
  dsh-x = pkgsLatest.callPackage ../../local-deriv/dsh-x.nix { };
  mnemon = pkgsLatest.callPackage ../../local-deriv/mnemon.nix { };
in
{
  # DSH-X generates its CLI entry point outside the Nix store.
  home.sessionPath = [ "${config.xdg.configHome}/DSH/bin" ];

  home.packages = with pkgsLatest; [
    codex
    codexDesktop
    pi-coding-agent
    paseo
    paseo.desktop
    antigravity-cli
    antigravity-hub
    agentReach
    opencli
    mcporter
    # DSH-X launcher: provides a host-native alternative to the Arch container.
    # It reads the same ~/.dsh (DSH_HOME) and web profile, and its
    # core layer updates through npm into ~/.config/DSH, so the store stays
    # read-only. Its wrapper provides a compatible Node runtime and pnpm;
    # `dsh plugin` forwards to pnpm inside the profile directory.
    dsh-x
    mnemon
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
