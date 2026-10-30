{
  lib,
  pkgs,
  kos,
}:
let
  deploy = pkgs.callPackage "${kos.src}/packaging/nix/sync-shell.nix" { inherit kos; };
in
pkgs.writeShellScript "kos-shell-init" ''
  set -euo pipefail
  export PATH=${lib.makeBinPath [ pkgs.coreutils ]}:"$PATH"
  shell_config="''${1:-$HOME/.config/quickshell/kos}"
  marker="$shell_config/.nix-shell-source"
  # A new package (including rollback) deploys once. Manual repair remains
  # available through KOS_SYNC_FORCE=1 kos-ctl sync.
  if [[ "''${KOS_SYNC_FORCE:-0}" != 1 && -f "$marker" &&
        -f "$shell_config/shell.qml" && -d "$shell_config/shared/qml" &&
        -d "$shell_config/Kos/Spatial3D" && -d "$shell_config/Kos/SurfaceShape" ]] &&
      [[ "$(cat "$marker")" == ${lib.escapeShellArg (toString kos)} ]]; then
    exit 0
  fi
  ${deploy} "$shell_config"
  printf '%s\n' ${lib.escapeShellArg (toString kos)} > "$marker"
''
