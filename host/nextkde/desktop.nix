{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  shell = pkgs.callPackage ../../local-deriv/nextkde-shell.nix { src = inputs.nextkde; };
  syncShell = pkgs.callPackage ../../local-deriv/nextkde-sync-shell.nix { kos = shell; };
  shellControl = pkgs.callPackage "${inputs.nextkde}/packaging/nix/kos-ctl.nix" {
    sync-shell = syncShell;
  };
  apps = pkgs.callPackage ../../local-deriv/nextkde-apps.nix { src = inputs.nextkde; };
  spatialModels = pkgs.callPackage ../../local-deriv/nextkde-spatial-models.nix { };
  platform = shell.kos-platform;
  # systemd expands %h/%u/%S, not shell variables. Mirror the NixOS profile paths
  # so applications launched by KOS inherit the wrappers and user packages.
  sessionPath = lib.concatStringsSep ":" (
    [
      config.security.wrapperDir
      "%h/.local/bin"
      "%h/bin"
    ]
    ++ map (
      profile:
      "${lib.replaceStrings [ "$HOME" "$USER" "\${XDG_STATE_HOME}" ] [ "%h" "%u" "%S" ] profile}/bin"
    ) config.environment.profiles
    ++ [
      (lib.makeBinPath [
        pkgs.bash
        pkgs.coreutils
        pkgs.findutils
        pkgs.gnugrep
        pkgs.gnused
      ])
    ]
  );
in
{
  environment.etc."specialisation".text = "nextkde";
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.defaultSession = "plasma";

  # Qt's Fcitx client-side candidate window reads Theme only, ignoring DarkTheme.
  # KWin's native input path lets the daemon follow the appearance portal. Qt 6
  # keeps module fallbacks for applications without a usable Wayland frontend.
  environment.variables = {
    QT_IM_MODULE = lib.mkForce "";
    QT_IM_MODULES = "wayland;fcitx;ibus";
  };

  # The platform daemon looks in the system profile, not Home Manager's PATH.
  environment.systemPackages = with pkgs; [
    wl-clipboard
    cliphist
    brightnessctl
    whitesur-kde # WhiteSur / WhiteSurDark palettes for KOS light/dark switching
    quickshell
    shell
    shellControl
    shell.kosctl
    shell.kwin-dock-window-animation
    shell.kwin-stage-animation
    shell.kwin-context-menu-input
    shell.kwin-effects-glass
    shell.kwin-kos-bridge
    shell.kwin-kos-decoration
    shell.weather
    (lib.getBin pulseaudio) # pactl: outputs, per-application mixer and audio events
    (lib.getBin glib) # gio: trash, Open With and MIME associations
    apps
    (pkgs.callPackage ../../local-deriv/nextkde-qdbus6.nix { })
    (pkgs.callPackage ../../local-deriv/nextkde-session-tools.nix { })
  ];
  environment.pathsToLink = [ "/lib/kwin" ];
  services.dbus.packages = [ apps ];
  # Define the PIM unit below instead of importing its upstream session ordering.

  # KOS provides its own PIM service; the KDE PIM suite is unnecessary.
  programs.kde-pim.enable = false;

  # Own the Plasma integration here: upstream has no package injection option.
  # Services, kos-ctl and plugins share one patched package; no priority-based
  # overlay of a second complete KOS installation is needed.
  systemd.user.services =
    lib.mapAttrs
      (
        _: unit:
        {
          wantedBy = [ "plasma-workspace.target" ];
          partOf = [ "plasma-workspace.target" ];
          # Plasma starts its workspace before graphical-session.target.
          after = [ "plasma-kwin_wayland.service" ];
        }
        // unit
      )
      {
        kos-shell-init = {
          description = "KOS shell config initializer";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = syncShell;
          };
          preStart = ''
            # An invalid appearance file must not prevent the desktop from starting.
            if ! ${pkgs.python3}/bin/python3 ${./bootstrap.py} ${spatialModels}/models; then
              echo "Spatial setup skipped; inspect kos-shell-init journal before retrying." >&2
            fi
          '';
        };
        kos-platform = {
          description = "KOS platform integration service";
          serviceConfig = {
            Type = "simple";
            ExecStart = "${platform}/libexec/kos-platform daemon";
            Environment = [
              "KOS_PLATFORM_KWIN_SCRIPT=${platform}/share/kos/platform/kwin/window-bridge.js"
              "PATH=${sessionPath}"
            ];
            Restart = "on-failure";
            RestartSec = 2;
          };
        };
        kos-data = {
          description = "KOS persistent data service";
          serviceConfig = {
            Type = "simple";
            ExecStart = "${shell}/libexec/kos-data-service";
            Environment = [ "PATH=${sessionPath}" ];
            Restart = "on-failure";
            RestartSec = 2;
          };
        };
        kos-shell = {
          description = "KOS Quickshell desktop shell";
          requires = [
            "kos-platform.service"
            "kos-shell-init.service"
          ];
          wants = [ "kos-data.service" ];
          after = [
            "plasma-kwin_wayland.service"
            "plasma-plasmashell.service"
            "kos-platform.service"
            "kos-data.service"
            "kos-shell-init.service"
            "kos-pim-service.service"
          ];
          serviceConfig = {
            Type = "simple";
            KillMode = "process";
            ExecStart = "${pkgs.quickshell}/bin/quickshell --no-duplicate -c kos";
            Environment = [
              "QS_DISABLE_FILE_WATCHER=1"
              "MALLOC_ARENA_MAX=2"
              "QML2_IMPORT_PATH=%h/.config/quickshell/kos:${shell.kos-spatial3d}/lib/qt6/qml:${pkgs.kdePackages.qtquick3d}/lib/qt-6/qml:${pkgs.kdePackages.qt5compat}/lib/qt-6/qml"
              "QT_PLUGIN_PATH=${pkgs.kdePackages.qtsvg}/lib/qt-6/plugins:${pkgs.kdePackages.qtimageformats}/lib/qt-6/plugins"
              "PATH=${sessionPath}"
            ];
            Restart = "on-failure";
            RestartSec = 2;
          };
        };
        kos-pim-service = {
          description = "KOS calendar, task, and reminder service";
          serviceConfig = {
            Type = "dbus";
            BusName = "org.nextkde.Kos.Pim1";
            ExecStart = "${apps}/bin/kos-pim-service";
            Restart = "on-failure";
            RestartSec = 2;
            Slice = "background.slice";
          };
        };
      };

  # Pin input-method selector and variant-scoped Dolphin palette override at
  # system level; desktop plugins, decorations, and WhiteSur defaults belong
  # to Home Manager (programs.plasma).
  # The main desktop persists an app-specific Matugen scheme in dolphinrc.
  # KColorSchemeManager treats an empty scheme as following the KDE palette.
  # Override only that key in this variant; retain the user's original file.
  environment.etc."xdg/dolphinrc".text = ''
    [UiSettings]
    ColorScheme[$i]=
  '';
  environment.etc."xdg/kwinrc".text = ''
    [Wayland]
    InputMethod[$i]=/run/current-system/sw/share/applications/fcitx5-wayland-launcher.desktop
  '';

  # KDE owns the mode/accent. kos-colors publishes separate Fcitx5 palettes;
  # do not select or modify the main desktop's mellow-matugen theme files.
  i18n.inputMethod.fcitx5.settings.addons.classicui.globalSection = {
    Theme = "mellow-kde";
    DarkTheme = "mellow-kde-dark";
    UseDarkTheme = "True";
  };
}
