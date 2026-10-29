{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  apps = pkgs.callPackage ../../local-deriv/nextkde-apps.nix { src = inputs.nextkde; };
  spatialModels = pkgs.callPackage ../../local-deriv/nextkde-spatial-models.nix { };
  platform = pkgs.callPackage ../../local-deriv/nextkde-platform-whitesur.nix {
    src = inputs.nextkde;
  };
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
  services.kos.enable = true;
  services.kos.weather.enable = true;

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
    (lib.hiPrio platform) # Match KWin's desktop-entry permission to ExecStart.
    (lib.getBin pulseaudio) # pactl: outputs, per-application mixer and audio events
    (lib.getBin glib) # gio: trash, Open With and MIME associations
    apps
    (pkgs.callPackage ../../local-deriv/nextkde-qdbus6.nix { })
    (pkgs.callPackage ../../local-deriv/nextkde-session-tools.nix { })
  ];
  services.dbus.packages = [ apps ];
  # Define the PIM unit below instead of importing its upstream session ordering.

  # KOS provides its own PIM service; the KDE PIM suite is unnecessary.
  programs.kde-pim.enable = false;

  # Upstream targets every graphical session. This variant starts KOS only with
  # Plasma, and stops its daemons with the Plasma session.
  systemd.user.services = lib.mkMerge [
    (lib.genAttrs
      [
        "kos-shell-init"
        "kos-platform"
        "kos-data"
        "kos-shell"
      ]
      (name: {
        wantedBy = lib.mkForce [ "plasma-workspace.target" ];
        partOf = lib.mkForce [ "plasma-workspace.target" ];
        # The last Environment= assignment wins. Preserve upstream's Qt/KOS
        # variables while replacing its truncated PATH after those assignments.
        serviceConfig.Environment = lib.mkAfter [ "PATH=${sessionPath}" ];
        # Plasma's workspace target is Before=graphical-session.target. Keeping
        # upstream's After=graphical-session.target would create an ordering cycle.
        after = lib.mkForce (
          [ "plasma-kwin_wayland.service" ]
          ++ lib.optionals (name == "kos-shell") [
            "plasma-plasmashell.service"
            "kos-platform.service"
            "kos-data.service"
            "kos-shell-init.service"
            "kos-pim-service.service"
          ]
        );
      })
    )
    {
      # Upstream hardcodes BreezeLight/BreezeDark. Replace only this daemon;
      # keep the shell, KWin plugins and their package identities unchanged.
      kos-platform.serviceConfig.ExecStart = lib.mkForce "${platform}/libexec/kos-platform daemon";
      # The widgets only read a snapshot; they do not activate the D-Bus service.
      # Dependency lists cannot be cleared by a drop-in. Replace the full unit
      # to remove upstream's After=graphical-session.target, retaining its D-Bus
      # readiness and restart semantics.
      kos-pim-service = {
        description = "KOS calendar, task, and reminder service";
        wantedBy = [ "plasma-workspace.target" ];
        after = [ "plasma-kwin_wayland.service" ];
        partOf = [ "plasma-workspace.target" ];
        serviceConfig = {
          Type = "dbus";
          BusName = "org.nextkde.Kos.Pim1";
          ExecStart = "${apps}/bin/kos-pim-service";
          Restart = "on-failure";
          RestartSec = 2;
          Slice = "background.slice";
        };
      };
      kos-shell-init.preStart = ''
        # Materialize only the effective ShellPackage key. Upstream's colour
        # reader ignores /etc/xdg; retain any explicit user-selected package
        # and leave all other Plasma settings writable and untouched.
        shellPackage=$(${pkgs.kdePackages.kconfig}/bin/kreadconfig6 \
          --file plasmashellrc --group Shell --key ShellPackage --default org.kos.desktop)
        ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
          --file "$HOME/.config/plasmashellrc" --group Shell --key ShellPackage "$shellPackage"
        # An invalid appearance file must not prevent the desktop from starting.
        if ! ${pkgs.python3}/bin/python3 ${./bootstrap.py} ${spatialModels}/models; then
          echo "Spatial setup skipped; inspect kos-shell-init journal before retrying." >&2
        fi
      '';
    }
  ];

  # Mirror kosctl's core desktop takeover without running its mutable installer.
  # plasmashell stays alive for wallpaper; KOS owns the bar, dock and desktop files.
  # These are defaults, not immutable user files: KOS Settings and Stage mode
  # must be able to write their overrides to ~/.config/kwinrc.
  environment.etc."xdg/plasmashellrc".text = ''
    [Shell]
    ShellPackage=org.kos.desktop
  '';
  # The main desktop persists an app-specific Matugen scheme in dolphinrc.
  # KColorSchemeManager treats an empty scheme as following the KDE palette.
  # Override only that key in this variant; retain the user's original file.
  environment.etc."xdg/dolphinrc".text = ''
    [UiSettings]
    ColorScheme[$i]=
  '';
  environment.etc."xdg/kwinrc".text = ''
    # Pin only the input-method selector; all other KWin settings stay writable.
    # A stable profile path also survives Fcitx package updates.
    [Wayland]
    InputMethod[$i]=/run/current-system/sw/share/applications/fcitx5-wayland-launcher.desktop

    [Plugins]
    blurEnabled=false
    glassEnabled=true
    kos_bridgeEnabled=true
    kos_context_menu_inputEnabled=true
    kos_dock_window_animationEnabled=true

    [org.kde.kdecoration2]
    library=kos_decoration
  '';

  # No Darkman/matugen runtime in this variant; retain a built-in Fcitx5 fallback.
  i18n.inputMethod.fcitx5.settings.addons.classicui.globalSection = {
    Theme = lib.mkForce "default";
    DarkTheme = lib.mkForce "default-dark";
  };
}
