{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cacheRoot = "${config.xdg.cacheHome}/kos-colors";
  kdeGlobals = "${config.xdg.configHome}/kdeglobals";
  fcitxThemes = inputs.fcitx5-matugen-theme.packages.${pkgs.stdenv.hostPlatform.system}.both-blur;
  fcitxTemplates = "${fcitxThemes}/share/matugen/fcitx5-matugen-theme";
  # Disable only the compositor request; retain the translucent Mellow assets.
  fcitxThemeTemplate =
    mode:
    pkgs.runCommand "mellow-kde-${mode}-no-blur-template" { } ''
      substitute \
        ${fcitxTemplates}/${
          if mode == "light" then "mellow-matugen" else "mellow-matugen-dark"
        }/theme.conf.tpl \
        "$out" --replace-fail 'EnableBlur=True' 'EnableBlur=False'
    '';
  modeTemplate =
    mode: name: source:
    pkgs.runCommand "kos-${name}-${mode}-template" { } ''
      ${pkgs.gnused}/bin/sed \
        -e 's/\.default\./.${mode}./g' \
        -e 's/__MATUGEN_MODE__/${mode}/g' ${source} > "$out"
    '';
  appTemplates =
    lib.concatMap
      (mode: [
        {
          input = fcitxThemeTemplate mode;
          output = "${mode}/fcitx5/theme.conf";
        }
        {
          input = "${fcitxTemplates}/${
            if mode == "light" then "mellow-matugen" else "mellow-matugen-dark"
          }/highlight.svg.tpl";
          output = "${mode}/fcitx5/highlight.svg";
        }
        {
          input = modeTemplate mode "nvim" ./matugen/nvim-colors.lua.tpl;
          output = "${mode}/nvim-colors.lua";
        }
        {
          input = modeTemplate mode "zellij" ./matugen/zellij-theme.kdl.tpl;
          output = "${mode}/zellij.kdl";
        }
      ])
      [
        "light"
        "dark"
      ];
  manifest = pkgs.writeText "kos-colors.json" (
    builtins.toJSON {
      inherit cacheRoot kdeGlobals;
      matugen = "${pkgs.matugen}/bin/matugen";
      templates = appTemplates ++ [
        {
          input = modeTemplate "dark" "btop" ./matugen/btop.theme.tpl;
          output = "dark/btop.theme";
        }
        {
          input = modeTemplate "dark" "yazi" ./matugen/yazi-flavor.toml.tpl;
          output = "dark/yazi.toml";
        }
        {
          input = modeTemplate "dark" "modernz" ./matugen/modernz.conf.tpl;
          output = "dark/modernz.conf";
        }
      ];
      fcitxAssets = {
        light = "${fcitxThemes}/share/fcitx5/themes/mellow-matugen";
        dark = "${fcitxThemes}/share/fcitx5/themes/mellow-matugen-dark";
      };
      fcitxConfig = "${config.xdg.configHome}/fcitx5/conf/classicui.conf";
      fcitxReload = "${pkgs.fcitx5}/bin/fcitx5-remote";
      btopReload = "${pkgs.procps}/bin/pkill";
    }
  );
  synchronize = pkgs.writeShellScript "kos-colors" ''
    exec ${pkgs.python3}/bin/python3 ${./kde-colors.py} --manifest ${manifest} "$@"
  '';
  # Shared apps keep their existing theme names. Only this variant points those
  # names into its private cache; the main runtime owns its original files.
  appFiles = {
    ".cache/matugen/nvim-colors.lua" = "selected/nvim-colors.lua";
    ".config/zellij/themes/matugen.kdl" = "selected/zellij.kdl";
    ".config/btop/themes/matugen.theme" = "current/dark/btop.theme";
    ".config/yazi/flavors/matugen-runtime.yazi/flavor.toml" = "current/dark/yazi.toml";
    ".config/mpv/script-opts/modernz.conf" = "current/dark/modernz.conf";
  };
in
{
  home.packages = [ pkgs.matugen ];
  programs.btop.settings.color_theme = "matugen";
  programs.zellij.settings.theme = "matugen";
  programs.yazi.theme.flavor.dark = "matugen-runtime";
  home.file =
    (lib.mapAttrs (_: path: {
      source = config.lib.file.mkOutOfStoreSymlink "${cacheRoot}/${path}";
      force = true;
    }) appFiles)
    // {
      ".local/bin/kos-colors" = {
        source = synchronize;
        executable = true;
      };
    };
  xdg.configFile."kos-colors/config.json".source = manifest;
  xdg.dataFile =
    lib.genAttrs
      [
        "fcitx5/themes/mellow-kde"
        "fcitx5/themes/mellow-kde-dark"
      ]
      (name: {
        source = config.lib.file.mkOutOfStoreSymlink (
          "${cacheRoot}/current/${if lib.hasSuffix "-dark" name then "dark" else "light"}/fcitx5"
        );
        force = true;
      });

  systemd.user.services.kos-colors = {
    Unit = {
      Description = "Synchronize application colors from KDE";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
      ConditionPathExists = kdeGlobals;
      # Fast accent-picker changes must not disable the path's service.
      StartLimitIntervalSec = 0;
    };
    Service = {
      Type = "oneshot";
      ExecStart = synchronize;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # systemd already watches the file; no extra D-Bus client or polling daemon.
  # KOS forwards wallpaper accents to Plasma, which saves the resulting palette.
  systemd.user.paths.kos-colors = {
    Unit = {
      Description = "Watch KDE colors for application theme updates";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Path.PathChanged = kdeGlobals;
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
