{ inputs, ... }:
{
  # 主 DE（Hyprland + niri）：共享基础 + 主题域（home/theme/）+ compositor 域（home/de/）。
  imports = [
    ./base.nix
    # The pinned module's sole activation entry replaces writable Fcitx theme
    # directories without HM's `run`. Guard its entry, not a fork of its installer.
    # Return to the direct module import once upstream honors DRY_RUN itself.
    (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      inputs.fcitx5-matugen-theme.homeManagerModules.default {
        inherit config pkgs;
        lib = lib.recursiveUpdate lib {
          hm.dag.entryAfter = import ./theme/run-after.nix lib "installFcitx5MatugenRuntimeThemes";
        };
      }
    )
    ./theme/gtk-matugen.nix
    ./theme/runtime.nix
    ./theme/wallpaper.nix
    ./de
  ];

  services.udiskie.enable = true;
  programs.btop.settings.color_theme = "matugen";
  programs.zellij.settings.theme = "matugen";
  programs.yazi.theme.flavor.dark = "matugen-runtime";
}
