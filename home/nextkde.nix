{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.plasma-manager.homeModules.plasma-manager
    ./base.nix
    ./de/foot.nix
    ./theme/kde-runtime.nix
  ];

  home.packages = [
    (pkgs.callPackage ../local-deriv/kmusic.nix { })
    inputs.plasma-manager.packages.${pkgs.stdenv.hostPlatform.system}.rc2nix
  ];

  # Declarative KDE management via plasma-manager
  programs.plasma = {
    enable = true;

    configFile = {
      # Plasmashell shell package: directs Plasma to use KOS desktop shell,
      # materializing ~/.config/plasmashellrc for upstream KOS colour picker.
      "plasmashellrc"."Shell"."ShellPackage" = "org.kos.desktop";

      # KDE global appearance defaults: sets WhiteSur light/dark package pair
      # to prevent login-time Breeze fallback while keeping user choices writable.
      "kdeglobals"."KDE" = {
        LookAndFeelPackage = "com.github.vinceliuice.WhiteSur";
        DefaultLightLookAndFeel = "com.github.vinceliuice.WhiteSur";
        DefaultDarkLookAndFeel = "com.github.vinceliuice.WhiteSur-dark";
      };

      # Dolphin color scheme: overrides any Matugen scheme from the main DE,
      # keeping Dolphin synchronized with KDE system colors.
      "dolphinrc"."UiSettings"."ColorScheme" = {
        value = "";
        immutable = true;
      };

      # KWin plugins and window decoration for NextKDE desktop
      "kwinrc" = {
        Wayland = {
          InputMethod = {
            value = "/run/current-system/sw/share/applications/fcitx5-wayland-launcher.desktop";
            immutable = true;
          };
        };
        Plugins = {
          blurEnabled = false;
          glassEnabled = true;
          kos_bridgeEnabled = true;
          kos_context_menu_inputEnabled = true;
          kos_dock_window_animationEnabled = true;
        };
        "org.kde.kdecoration2" = {
          library = "kos_decoration";
        };
      };
    };
  };

  # An empty managed value removes just this inherited override in merge mode.
  # Keep unrelated Flatpak permissions and environment overrides writable.
  services.flatpak.overrides.settings.global.Environment.GTK_THEME = "";

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
