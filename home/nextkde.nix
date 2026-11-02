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
    ./theme/qt-whitesur.nix
  ];

  home.packages = [
    inputs.plasma-manager.packages.${pkgs.stdenv.hostPlatform.system}.rc2nix
  ];

  # Preserve the rendering preferences selected in Plasma's Fonts KCM.
  # Keep HM's font search paths separate from the rendering policy.
  fonts.fontconfig = {
    antialiasing = true;
    hinting = "full";
    subpixelRendering = "rgb";
  };

  # GUI preferences are captured here after review; keep KDE files writable.
  programs.plasma = {
    enable = true;
    overrideConfig = false;
    immutableByDefault = false;

    kwin.effects = {
      translucency.enable = true;
      wobblyWindows.enable = true;
    };
    input.keyboard.layouts = [ { layout = "us"; } ];
    # Only saved non-default Plasma shortcuts. KOS owns its own bindings and
    # releases Meta+Tab from KWin's window switcher at runtime.
    shortcuts = {
      kwin = {
        MinimizeAll = "Meta+Shift+D";
        minimizeAllOthers = "Meta+Shift+O";
      };
      plasmashell = {
        "next activity" = "Meta+A";
        "previous activity" = "Meta+Shift+A";
      };
    };

    configFile = {
      # Plasmashell shell package: directs Plasma to use KOS desktop shell,
      # materializing ~/.config/plasmashellrc for upstream KOS colour picker.
      "plasmashellrc"."Shell"."ShellPackage" = "org.kos.desktop";

      # KDE global appearance defaults: sets WhiteSur light/dark package pair
      # to prevent login-time Breeze fallback while keeping user choices writable.
      "kdeglobals"."KDE" = {
        widgetStyle = "kvantum";
        AutomaticLookAndFeel = true;
        LookAndFeelPackage = "com.github.vinceliuice.WhiteSur";
        DefaultLightLookAndFeel = "com.github.vinceliuice.WhiteSur";
        DefaultDarkLookAndFeel = "com.github.vinceliuice.WhiteSur-dark";
      };

      "kdeglobals"."General" = {
        accentColorFromWallpaper = true;
        XftAntialias = true;
        XftHintStyle = "hintfull";
        XftSubPixel = "rgb";
      };

      # KWin plugins and window decoration for NextKDE desktop
      "kwinrc" = {
        # The high-level number option also rewrites desktop IDs. Preserve the
        # existing IDs and per-desktop layouts by owning only count and rows.
        Desktops = {
          Number = 3;
          Rows = 1;
        };
        ElectricBorders = {
          BottomLeft = "ShowDesktop";
          TopRight = "KRunner";
        };
        NightColor.Active = false;
        Plugins = {
          desktopchangeosdEnabled = true;
          minimizeallEnabled = true;
          sheetEnabled = true;
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
      # The high-level touchpad module also removes unspecified properties.
      # Own only the GUI preferences captured here, leaving other tuning intact.
      "kcminputrc"."Libinput/2362/597/UNIW0001:00 093A:0255 Touchpad" = {
        Enabled = true;
        NaturalScroll = true;
      };
      "kcminputrc"."Libinput/2362/597/UNIW0001:00 093A:0255 Mouse" = {
        NaturalScroll = false;
        ScrollMethod = 4;
      };
      "plasma-localerc"."Formats".LANG = "zh_CN.UTF-8";
      "kded_device_automounterrc"."General" = {
        AutomountEnabled = true;
        AutomountOnLogin = true;
        AutomountOnPlugin = true;
        AutomountUnknownDevices = true;
      };
      "dolphinrc" = {
        # Clear the main desktop's per-app palette; Plasma owns KDE colors.
        UiSettings.ColorScheme = "";
        General.LockPanels = false;
        "KFileDialog Settings" = {
          "Places Icons Auto-resize" = false;
          "Places Icons Static Size" = 22;
        };
      };
      "spectaclerc" = {
        General = {
          autoSaveImage = true;
          clipboardGroup = "PostScreenshotCopyImage";
        };
        ImageSave.imageSaveLocation = "file://${config.home.homeDirectory}/Pictures/Screenshots/";
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
}
