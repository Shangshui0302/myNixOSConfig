{
  lib,
  agentOrchestrator,
  distrobox,
  writeShellApplication,
  symlinkJoin,
}:
let
  dshBridge = writeShellApplication {
    name = "dsh";
    runtimeInputs = [ distrobox ];
    text = ''
      # ACP needs untouched pipes and identical host/container workspace paths.
      # Keep Node and DSH in Arch; the shared Nix store supplies AO's callback CLI.
      exec ${lib.getExe distrobox} enter --name arch --no-tty --no-workdir -- \
        /usr/bin/env --chdir "$PWD" \
        "PATH=${agentOrchestrator}/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin" \
        "DSH_HOME=''${DSH_HOME:-$HOME/.dsh}" \
        /usr/bin/node /usr/bin/dsh "$@"
    '';
  };
  cli = writeShellApplication {
    name = "ao";
    runtimeInputs = [ dshBridge ];
    text = ''
      export AO_DATA_DIR="''${AO_DATA_DIR:-$HOME/.ao}"
      export AO_RUN_FILE="''${AO_RUN_FILE:-$AO_DATA_DIR/running.json}"
      export DSH_HOME="''${DSH_HOME:-$HOME/.dsh}"
      exec ${agentOrchestrator}/bin/ao "$@"
    '';
  };
  gui = writeShellApplication {
    name = "agent-orchestrator";
    text = ''
      export AO_DATA_DIR="''${AO_DATA_DIR:-$HOME/.ao}"
      export AO_RUN_FILE="''${AO_RUN_FILE:-$AO_DATA_DIR/running.json}"
      # AO restores login-shell PATH before spawning its daemon. Apply the
      # private bridge after that step through the supported command override.
      export AO_DAEMON_COMMAND="${cli}/bin/ao daemon"
      # Native Wayland follows the compositor's fractional scale even when
      # a launcher omits XDG_SESSION_TYPE. Keep X11 sessions and user flags usable.
      displayArgs=()
      if [[ -n "''${WAYLAND_DISPLAY:-}" ]]; then
        displayArgs+=(--ozone-platform=wayland)
      fi
      exec ${agentOrchestrator}/bin/agent-orchestrator "''${displayArgs[@]}" "$@"
    '';
  };
in
symlinkJoin {
  name = "agent-orchestrator-distrobox-${agentOrchestrator.version}";
  paths = [
    cli
    gui
    agentOrchestrator
  ];
  postBuild = ''
    rm "$out/share/applications/agent-orchestrator.desktop"
    cp ${agentOrchestrator}/share/applications/agent-orchestrator.desktop \
      "$out/share/applications/agent-orchestrator.desktop"
    substituteInPlace "$out/share/applications/agent-orchestrator.desktop" \
      --replace-fail "Exec=${agentOrchestrator}/bin/agent-orchestrator" \
        "Exec=$out/bin/agent-orchestrator"
  '';
  passthru = { inherit dshBridge; };
  meta = agentOrchestrator.meta // {
    description = "Agent Orchestrator with an ACP bridge to DSH in the Arch Distrobox";
  };
}
