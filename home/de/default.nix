{ ... }:
{
  # 主 DE compositor 域：Hyprland/niri、终端、桌面 shell、快捷键路由。
  # 颜色/壁纸/主题在 ../theme/（由 home.nix 引入），本目录不做主题配置。
  imports = [
    ./hyprland.nix
    ./foot.nix
    ./noctalia.nix
    ./caelestia-shell.nix
    ./niri.nix
    ./shell-switcher.nix
  ];

  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    SDL_IM_MODULE = "fcitx";
  };
}
