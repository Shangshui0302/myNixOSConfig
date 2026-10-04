{
  pkgs,
  inputs,
  osConfig,
  ...
}:

let
  strata = inputs.strata-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.strata;
in
{
  # 主 DE 与 GNOME 共用 Nautilus/Sushi/Dolphin；Strata 仅在主 DE 提供。
  home.packages =
    with pkgs;
    [
      ouch
      rich-cli
      p7zip
      unzip
      file-roller
      nautilus
      sushi
      ffmpegthumbnailer
      tumbler
      dragon-drop
      kdePackages.dolphin
    ]
    ++ pkgs.lib.optionals (!osConfig.services.desktopManager.gnome.enable) [ strata ];
}
