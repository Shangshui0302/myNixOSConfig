{
  pkgs,
  lib,
  inputs,
  osConfig,
  ...
}:

let
  strata = inputs.strata-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.strata;
  mainDesktop = !osConfig.services.desktopManager.plasma6.enable;
in
{
  # Plasma 自带 Dolphin，Strata 仅在主 DE 提供。
  home.packages =
    with pkgs;
    [
      ouch
      rich-cli
      p7zip
      unzip
      ffmpegthumbnailer
      dragon-drop
    ]
    ++ lib.optionals mainDesktop [
      kdePackages.dolphin
      kdePackages.ark
      strata
    ];

  # “在文件管理器中显示”走 FileManager1，独立于目录 MIME 默认关联。
  # 包保留了带绝对 Exec 路径的可选模板。
  xdg.dataFile."dbus-1/services/org.freedesktop.FileManager1.service" = lib.mkIf mainDesktop {
    source = "${strata}/share/strata/io.github.lgse.Strata.FileManager1.service";
  };
}
