{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./base.nix
    ./de/foot.nix
  ];

  # Reuse the terminal preferences without the main desktop's Hyprland focus hook.
  programs.foot.settings."desktop-notifications".command =
    lib.mkForce "${pkgs.libnotify}/bin/notify-send --app-name foot -- \${title} \${body}";

  # KScreenLocker selects its theme from the active Plasma shell package.
  # Installing the theme does not replace authentication or apply a global theme.
  xdg.dataFile = {
    "plasma/shells/org.kos.desktop/metadata.json".source =
      "${inputs.nextkde}/apps/lockscreen/metadata.json";
    "plasma/shells/org.kos.desktop/contents/defaults".source =
      "${inputs.nextkde}/apps/lockscreen/contents/defaults";
    "plasma/shells/org.kos.desktop/contents/lockscreen" = {
      recursive = true;
      # The shell updates LockFeed.qml at runtime. Keep its parent writable and
      # manage only static theme files, otherwise file.copy targets the store.
      source = builtins.path {
        path = "${inputs.nextkde}/apps/lockscreen/contents/lockscreen";
        name = "kos-lockscreen-static";
        filter = path: _: builtins.baseNameOf path != "LockFeed.qml";
      };
    };
  };

  home.activation.nextkdeLockscreenDirectory =
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
      ''
        themeDir=${lib.escapeShellArg "${config.xdg.dataHome}/plasma/shells/org.kos.desktop/contents/lockscreen"}
        # Home Manager does not replace an old whole-directory link when switching
        # to recursive links. Remove only a link owned by a previous HM generation.
        if [ -L "$themeDir" ]; then
          case "$(${pkgs.coreutils}/bin/readlink "$themeDir")" in
            /nix/store/*-home-manager-files/*)
              run ${pkgs.coreutils}/bin/unlink "$themeDir"
              ;;
          esac
        fi
      '';

  home.activation.nextkdeLockFeed = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    feed=${lib.escapeShellArg "${config.xdg.dataHome}/plasma/shells/org.kos.desktop/contents/lockscreen/LockFeed.qml"}
    if [ ! -e "$feed" ]; then
      run ${pkgs.coreutils}/bin/install -Dm644 \
        ${inputs.nextkde}/apps/lockscreen/contents/lockscreen/LockFeed.qml "$feed"
    fi
  '';

  # The shared battery policy stays available; desktop appearance belongs to KOS.
  powerActions.darkMode = false;
  powerActions.hyprlandEffects.enable = false;
  home.pointerCursor.hyprcursor.enable = lib.mkForce false;
}
