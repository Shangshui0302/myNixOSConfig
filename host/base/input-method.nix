{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  gnome = config.services.desktopManager.gnome.enable;
in
{
  environment.variables = {
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };
  environment.pathsToLink = [ "/share/fcitx5" ];

  # Fcitx5（两 DE 共享核心，差异用 option 表达）：
  # - 核心 addons（rime/chinese-addons/configtool/qt）+ kimpanel 两 DE 都要
  # - 主桌面（Hyprland/niri）：fcitx5-gtk 桥 + 主题 addons + classicui 候选窗
  #   （GNOME Wayland 走 text-input-v3 + kimpanel 扩展绘制候选窗，不用 classicui）
  # SVG 渲染优化已进入上游 5.1.23，使用 nixpkgs 原包，避免重复应用旧补丁。
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    fcitx5.addons =
      with pkgs;
      [
        (inputs.wetypex.packages.${pkgs.stdenv.hostPlatform.system}.fcitx5-wetypex.override {
          # true restores WeTypeX's controls for the shared Fcitx5 theme/font.
          enableWeTypeTheme = false;
          enableAI = true;
          enableVoice = true;
          enableLayerShell = true;
          # First-run values only; existing GUI preferences remain user-owned.
          defaultSettings = { };
        })
        (fcitx5-rime.override {
          rimeDataPkgs = [
            rime-ice
            rime-moegirl
            rime-zhwiki
          ];
        })
        qt6Packages.fcitx5-chinese-addons
        qt6Packages.fcitx5-configtool
        kdePackages.fcitx5-qt
      ]
      ++ lib.optionals (!gnome) [
        fcitx5-gtk
        fcitx5-mellow-themes
        fcitx5-material-color
        catppuccin-fcitx5
      ];
    # kimpanel addon 强制启用：GNOME Wayland 候选窗定位必需（GNOME 只实现 text-input-v3、
    # 无全局坐标，必须靠 kimpanel 扩展绘制候选窗）。已在运行时 ~/.config/fcitx5/config 的
    # [Behavior/DisabledAddons] 中移除 kimpanel，此声明防止再次被禁用。
    fcitx5.settings.globalOptions.Behavior.EnabledAddons = "kimpanel";
    # classicui 系统级回退配置（仅主桌面；GNOME 候选窗由 kimpanel 扩展绘制）。
    # theme-apply 为 GTK Wayland 客户端写入当前模式的用户层 Theme。
    fcitx5.settings.addons.classicui.globalSection = lib.mkIf (!gnome) {
      Theme = "mellow-matugen";
      DarkTheme = "mellow-matugen-dark";
      UseDarkTheme = "True";
      "Vertical Candidate List" = "True";
    };
  };

}
