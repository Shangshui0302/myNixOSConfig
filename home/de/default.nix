{ lib, osConfig, ... }:
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
    ./polkit.nix
  ];

  home.pointerCursor.hyprcursor.enable = true;

  # Desktop-specific user entries take precedence over an old generic user
  # portals.conf. Reuse the system-generated files rather than a second policy.
  xdg.configFile = lib.genAttrs
    [
      "xdg-desktop-portal/hyprland-portals.conf"
      "xdg-desktop-portal/niri-portals.conf"
    ]
    (name: { source = osConfig.environment.etc."xdg/${name}".source; });

  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    SDL_IM_MODULE = "fcitx";
  };
}
