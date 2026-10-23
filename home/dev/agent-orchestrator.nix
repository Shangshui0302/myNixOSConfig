{ pkgs, ... }:
{
  home.packages = [
    (pkgs.callPackage ../../local-deriv/agent-orchestrator-distrobox.nix {
      agentOrchestrator = pkgs.callPackage ../../local-deriv/agent-orchestrator.nix { };
    })
  ];
}
