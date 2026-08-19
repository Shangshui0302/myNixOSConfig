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
    ./theme-mode.nix
    ./wallpaper.nix
  ];

  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    SDL_IM_MODULE = "fcitx";
  };
}
