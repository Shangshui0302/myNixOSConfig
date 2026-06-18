{ config, pkgs, ... }:

let
  fonts = import ../local-deriv/fonts.nix { inherit pkgs; };
  anthropic-fonts = import ../local-deriv/anthropic-fonts.nix { inherit pkgs; };
in

{
  environment.variables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    NIXOS_OZONE_WL = "1";
    EDITOR = "nvim";
    SUDO_EDITOR = "nvim";
    STEAM_FORCE_DESKTOPUI_SCALING = "2.0";
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORMTHEME = "qt5ct";
    GDK_SCALE = "2";
  };

  # Hyprland
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Fcitx5
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      (fcitx5-rime.override {
        rimeDataPkgs = [ rime-ice rime-moegirl rime-zhwiki ];
      })
      fcitx5-gtk
      qt6Packages.fcitx5-chinese-addons
      qt6Packages.fcitx5-configtool
      fcitx5-material-color
      catppuccin-fcitx5
      kdePackages.fcitx5-qt
    ];
  };

  # Fonts
  fonts.packages = with pkgs; [
    wqy_zenhei wqy_microhei
    noto-fonts-cjk-sans noto-fonts-cjk-serif
    source-han-serif source-han-sans
    fonts.pingfang-otf fonts.harmonyos-sans
    anthropic-fonts
    noto-fonts-color-emoji
    lxgw-wenkai sarasa-gothic
    arphic-ukai arphic-uming
    eb-garamond libertine
    nerd-fonts.jetbrains-mono nerd-fonts.fira-code
    nerd-fonts.caskaydia-mono nerd-fonts.iosevka
    nerd-fonts.geist-mono nerd-fonts.monaspace
    nerd-fonts.zed-mono nerd-fonts.symbols-only
    font-awesome
  ];

  services.libinput.enable = true;

  xdg.portal = {
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    config.hyprland = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
    };
  };

  # Terminal
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "monospace:size=8";
        dpi-aware = "yes";
        shell = "${pkgs.fish}/bin/fish";
      };
      "colors-dark" = {
        alpha = "0.8";
        background = "0e1019";
        foreground = "fffaf4";
        regular0  = "666666";
        regular1  = "ff000f";
        regular2  = "8ce10b";
        regular3  = "ffb900";
        regular4  = "008df8";
        regular5  = "6d43a6";
        regular6  = "00d8eb";
        regular7  = "ffffff";
        bright0   = "888888";
        bright1   = "ff2740";
        bright2   = "abe15b";
        bright3   = "ffd242";
        bright4   = "0092ff";
        bright5   = "9a5feb";
        bright6   = "67fff0";
        bright7   = "ffffff";
      };
    };
  };
}
