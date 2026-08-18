{ pkgs, ... }:

{
  home.packages = with pkgs; [
    qq localsend
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
          "/usr/share/fonts:ro"
          "xdg-data/fonts:ro"
          "/run/current-system/sw/share/fonts:ro"
        ];
        sockets = [ "x11" ];  # WeChat 4.1.1.7 Wayland 兼容问题，用 X11
      };
      Environment = {
        QT_IM_MODULE = "fcitx";
        GTK_IM_MODULE = "fcitx";
        XMODIFIERS = "@im=fcitx";
        ELECTRON_FORCE_SCALE_FACTOR = "1.5";
      };
    };
  };
}
