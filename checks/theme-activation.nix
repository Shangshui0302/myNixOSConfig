{
  pkgs,
  homeManager,
  host,
}:
let
  inherit (pkgs) lib;
  # Use the assembled DAG entries, including the locked third-party Fcitx action.
  # Redirect absolute home paths and session commands into each test fixture.
  probe = pkgs.writeShellScript "theme-session-probe" ''
    echo "called $*" >> "$CALLS"
    if [ "''${1:-}" = get ]; then echo light; fi
  '';
  steps =
    home: names:
    let
      kos = home.home.file.".local/bin/kos-colors".source or null;
    in
    lib.genAttrs names (
      name:
      builtins.replaceStrings
        (
          [
            home.home.homeDirectory
            "${pkgs.darkman}/bin/darkman"
            "${pkgs.waypaper}/bin/waypaper"
          ]
          ++ lib.optional (kos != null) (toString kos)
        )
        (
          [
            "home"
            "${probe}"
            "${probe}"
          ]
          ++ lib.optional (kos != null) "${probe}"
        )
        home.home.activation.${name}.data
    );
  fixtures = {
    main = steps host.home-manager.users.lishangshui [
      "setupMatugenGtkTheme"
      "setupDarkmanMode"
      "setupWaypaperTheme"
      "applyRuntimeTheme"
      "installFcitx5MatugenRuntimeThemes"
      "initializeWhiteSurQt"
    ];
    nextkde = steps host.specialisation.nextkde.configuration.home-manager.users.lishangshui [
      "initializeWhiteSurQt"
      "applyKdeColors"
    ];
  };
in
pkgs.runCommand "theme-activation-tests"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.bash
    ];
    HM_BASH_LIB = "${homeManager}/lib/bash/home-manager.sh";
    STEPS = pkgs.writeText "theme-activation-fixtures.json" (builtins.toJSON fixtures);
    SESSION_PROBE = probe;
  }
  ''
    python3 ${../tests/test_theme_activation.py} -v
    touch "$out"
  ''
