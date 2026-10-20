{
  lib,
  callPackage,
  symlinkJoin,
  makeWrapper,
  fish,
  communityOrca,
}:

let
  app = callPackage ./orca-ide.nix { inherit communityOrca; };
  dsh = callPackage ./orca-dsh.nix { orcaCli = app; };
in
symlinkJoin {
  name = "orca-ide-${app.version}";
  inherit (app) version meta;
  paths = [
    app
    dsh
  ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram "$out/bin/orca-ide" \
      --prefix PATH : ${lib.makeBinPath [ dsh ]} \
      --add-flags "--password-store=gnome-libsecret" \
      --run 'if [ -n "''${WAYLAND_DISPLAY:-}" ]; then set -- --ozone-platform=wayland "$@"; fi' \
      --set ORCA_CLI_COMMAND "$out/bin/orca-ide-cli" \
      --set SHELL ${lib.getExe fish}
  '';
}
