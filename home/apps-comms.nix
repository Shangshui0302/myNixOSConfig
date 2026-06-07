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
}
