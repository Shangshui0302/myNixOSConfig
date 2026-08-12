{ config, lib, pkgs, ... }:

let
  gnome = config.services.desktopManager.gnome.enable;
  anthropic-fonts = import ../../local-deriv/anthropic-fonts.nix { inherit pkgs; };
in

{
  # 共享桌面基础（两 DE 都要）：keyring / 字体 / X server / fcitx5 核心。

  # GNOME Keyring — 为 Electron/VS Code 类应用提供加密凭据存储
  services.gnome.gnome-keyring.enable = true;

  environment.variables = {
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    EDITOR = "nvim";
    SUDO_EDITOR = "nvim";
    STEAM_FORCE_DESKTOPUI_SCALING = "2.0";
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GDK_SCALE = "2";
  };

  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";

  # Fcitx5（两 DE 共享核心，差异用 option 表达）：
  # - 核心 addons（rime/chinese-addons/configtool/qt）+ kimpanel 两 DE 都要
  # - Hyprland 专属：fcitx5-gtk 桥 + 主题 addons + classicui 候选窗
  #   （GNOME Wayland 走 text-input-v3 + kimpanel 扩展绘制候选窗，不用 classicui）
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      (fcitx5-rime.override {
        rimeDataPkgs = [ rime-ice rime-moegirl rime-zhwiki ];
      })
      qt6Packages.fcitx5-chinese-addons
      qt6Packages.fcitx5-configtool
      kdePackages.fcitx5-qt
    ] ++ lib.optionals (!gnome) [
      fcitx5-gtk
      fcitx5-mellow-themes
      fcitx5-material-color
      catppuccin-fcitx5
    ];
    # kimpanel addon 强制启用：GNOME Wayland 候选窗定位必需（GNOME 只实现 text-input-v3、
    # 无全局坐标，必须靠 kimpanel 扩展绘制候选窗）。已在运行时 ~/.config/fcitx5/config 的
    # [Behavior/DisabledAddons] 中移除 kimpanel，此声明防止再次被禁用。
    fcitx5.settings.globalOptions.Behavior.EnabledAddons = "kimpanel";
    # classicui 候选窗主题（仅 Hyprland；GNOME 候选窗由 kimpanel 扩展绘制）
    fcitx5.settings.addons.classicui.globalSection = lib.mkIf (!gnome) {
      Theme = "mellow-wechat";
      DarkTheme = "mellow-wechat-dark";
      UseDarkTheme = "True";
      # 垂直候选窗（键名含空格，需引号）
      "Vertical Candidate List" = "True";
    };
  };

  # Fonts
  fonts.packages = with pkgs; [
    wqy_zenhei wqy_microhei
    noto-fonts-cjk-sans noto-fonts-cjk-serif
    source-han-serif source-han-sans

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

  fileSystems."/usr/share/fonts" = {
    device = "/run/current-system/sw/share/X11/fonts";
    fsType = "bind";
    options = [ "bind" "ro" ];
  };

  services.libinput.enable = true;
}
