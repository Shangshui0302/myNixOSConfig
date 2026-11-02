{
  pkgs,
  inputs,
  ...
}:

{
  environment.variables = {
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };
  environment.pathsToLink = [ "/share/fcitx5" ];

  # Fcitx5（两 DE 共享核心，差异用 option 表达）：
  # - 核心 addons（rime/chinese-addons/configtool/qt/gtk）由两个桌面共享
  # - 主桌面（Hyprland/niri）与 NextKDE 在各自会话层下沉主题 addons 与 classicui 配置
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
          enableAI = false;
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
        fcitx5-gtk
      ];
  };
}
