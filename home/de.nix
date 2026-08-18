{ inputs, ... }:
{
  # 主 DE（Hyprland + niri）：共享基础、主题与 compositor 用户配置。
  imports = [
    ./base.nix
    inputs.stylix.homeModules.stylix
    ./theme-de.nix
    ./de
  ];
}
