{ pkgs, ... }:

{
  home.packages = with pkgs; [
    qq telegram-desktop localsend

    # (pkgs.wechat.overrideAttrs (old: {
    #   src = pkgs.fetchurl {
    #     url = "https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.AppImage";
    #     sha256 = "0grv6xv2r0sdhx7p10bgsmnqmq4yhfzldq7h32msp3k5g4b2y42z";
    #   };
    #   postInstall = (old.postInstall or "") + ''
    #     wrapProgram $out/bin/wechat \
    #     --add-flags "--force-device-scale-factor=1.5"
    #   '';
    # }))
  ];

  services.flatpak.packages = [
    "com.tencent.WeChat"
  ];

  services.flatpak.overrides = {
    "com.tencent.WeChat" = {
      Context = {
        filesystems = [
          "~/Downloads:rw"
          "~/Documents:rw"
          "xdg-data/fonts:ro"
          "/run/current-system/sw/share/fonts:ro"
        ];
        sockets = [ "wayland" "fallback-x11" ];
      };
      Environment = {
        # 输入法
        QT_IM_MODULE = "fcitx";
        GTK_IM_MODULE = "fcitx";
        XMODIFIERS = "@im=fcitx";
        # 2K 缩放
        ELECTRON_FORCE_SCALE_FACTOR = "1.5";
        # 清除 NixOS 宿主泄露的 Qt/GTK 变量，避免 Flatpak 运行时加载不兼容插件导致 SIGABRT
        QT_PLUGIN_PATH = "";
        QT_QPA_PLATFORM = "";
        QT_QPA_PLATFORMTHEME = "";
        QT_AUTO_SCREEN_SCALE_FACTOR = "";
        GTK_PATH = "";
        QTWEBKIT_PLUGIN_PATH = "";
      };
    };
  };

  xdg.desktopEntries.qq = {
    name = "QQ";
    exec = "qq %U";
    icon = "qq";
    categories = [ "InstantMessaging" "Chat" ];
    settings = {
      StartupWMClass = "QQ";
    };
  };

  # xdg.desktopEntries.wechat = {
  #   name = "WeChat";
  #   exec = "wechat %U";
  #   icon = "wechat";
  #   categories = [ "InstantMessaging" "Chat" ];
  #   settings = {
  #     StartupWMClass = "wechat";
  #   };
  # };

  xdg.desktopEntries."com.tencent.WeChat" = {
    name = "WeChat";
    exec = "flatpak run com.tencent.WeChat %U";
    icon = "com.tencent.WeChat";
    categories = [ "InstantMessaging" "Chat" ];
    settings = {
      StartupWMClass = "com.tencent.WeChat";
    };
  };
}
