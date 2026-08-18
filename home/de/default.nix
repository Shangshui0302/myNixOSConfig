{ ... }:
{
  imports = [
    ./hyprland.nix
    ./foot.nix
    ./stylix.nix
    ./noctalia.nix
    ./caelestia-shell.nix
    ./niri.nix
    ./musicfox.nix
    ./shell-switcher.nix
    ./wallpaper.nix
  ];

  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    SDL_IM_MODULE = "fcitx";
    QT_QPA_PLATFORMTHEME = "qt5ct";
  };
}
