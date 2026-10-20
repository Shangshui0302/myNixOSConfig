{
  lib,
  writeShellApplication,
  symlinkJoin,
  distrobox,
  orcaCli,
}:

let
  bridge =
    name: launcher: options:
    writeShellApplication {
      inherit name;
      runtimeInputs = [ distrobox ];
      text = ''
        # DSH and its Node runtime stay in Arch; preserve Orca's callback CLI.
        orcaDshPath="/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin"
        if [[ -n "''${ORCA_CLI_BIN_DIR:-}" ]]; then
          orcaDshPath="$ORCA_CLI_BIN_DIR:$orcaDshPath"
        fi
        exec ${lib.getExe distrobox} enter --name arch -- \
          /usr/bin/env --chdir "/run/host$PWD" \
          "PATH=$orcaDshPath" "DSH_PERMISSION_MODE=workspace-write" "DSH_HOME=''${DSH_HOME:-$HOME/.dsh}" \
          "ORCA_CLI_COMMAND=${orcaCli}/bin/orca-ide-cli" \
          "ORCA_USER_DATA_PATH=''${XDG_CONFIG_HOME:-$HOME/.config}/orca" \
          /usr/bin/node ${launcher} ${options} "$@"
      '';
    };
  cli = bridge "dsh" "/usr/bin/dsh" "";
  tui =
    bridge "dsh-tui"
      ''"$HOME/distrobox/arch/.local/share/orca-dsh-tui/node_modules/@deepseek-harness-tui/dsh-tui/bin/dsh-tui.js"''
      ''--patch "$HOME/distrobox/arch/.local/share/orca-dsh-tui/node_modules/@deepseek-harness-tui/dsh-tui/cordis.patch.yml" --patch ${./orca-dsh/tui-overlay.yml} --backend dsh'';
in
symlinkJoin {
  name = "orca-dsh-bridge";
  paths = [
    cli
    tui
  ];
  meta.description = "Orca launch bridges to the existing Arch DSH installation";
}
