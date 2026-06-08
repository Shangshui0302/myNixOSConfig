{ pkgs, ... }:

{
  home.packages = with pkgs; [
    qq telegram-desktop localsend

    (wechat.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        wrapProgram $out/bin/wechat \
        --add-flags "--force-device-scale-factor=1.5"
      '';
    }))
  ];

  xdg.desktopEntries.qq = {
    name = "QQ";
    exec = "qq %U";
    icon = "qq";
    categories = [ "InstantMessaging" "Chat" ];
    settings = {
      StartupWMClass = "QQ";
    };
  };

  xdg.desktopEntries.wechat = {
    name = "WeChat";
    exec = "wechat --force-device-scale-factor=1.5 %U";
    icon = "wechat";
    categories = [ "InstantMessaging" "Chat" ];
    settings = {
      StartupWMClass = "wechat";
    };
  };
}
