{
  config,
  lib,
  pkgs,
  inputs,
  materialGnomeTheme,
  ...
}:
{
  # GNOME 变体入口（inheritParentConfig=false）：完全不继承 main 的 Hyprland 配置。
  # 系统层：共享基础 host/base（含 hardware）+ GNOME 专属 host/gnome/desktop.nix。
  # 用户层：home/gnome.nix（import 共享 home/base.nix + Material 主题）。
  imports = [
    ../base/default.nix
    inputs.sops-nix.nixosModules.sops
    inputs.home-manager.nixosModules.home-manager
    ./desktop.nix
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "hm-backup";
  home-manager.users.lishangshui = import ../../home/gnome.nix;
  home-manager.extraSpecialArgs = { inherit inputs materialGnomeTheme; };
}
