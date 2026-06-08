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

  xdg.desktopEntries.wechat = {
    name = "WeChat";
    exec = "wechat --force-device-scale-factor=1.5 %U";
    icon = "wechat";
    categories = [ "Network" "InstantMessaging" "Chat" ];
    settings = {
      StartupWMClass = "wechat";
    };
  };
}
