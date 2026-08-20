{ config, lib, pkgs, inputs, materialGnomeTheme, ... }:
{
  # GNOME 变体（inheritParentConfig=false）：完全不继承 main 的 Hyprland 配置。
  # 自备共享基础（host/base，含 hardware）+ GNOME 专属 + sops/home-manager。
  imports = [
    ../../host/base/default.nix
    inputs.sops-nix.nixosModules.sops
    inputs.home-manager.nixosModules.home-manager
    ./host.nix
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "hm-backup";
  home-manager.users.lishangshui = import ./home.nix;
  home-manager.extraSpecialArgs = { inherit inputs materialGnomeTheme; };
}
