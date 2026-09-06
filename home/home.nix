{ inputs, ... }:
{
  # 主 DE（Hyprland + niri）：共享基础 + 主题域（home/theme/）+ compositor 域（home/de/）。
  imports = [
    ./base.nix
    inputs.stylix.homeModules.stylix
    inputs.fcitx5-matugen-theme.homeManagerModules.default
    ./theme/gtk-matugen.nix
    ./theme/runtime.nix
    ./theme/wallpaper.nix
    ./theme/stylix.nix
    ./de
  ];
}
