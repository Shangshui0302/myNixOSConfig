{
  pkgs,
  lib,
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
    ++ lib.optionals (!osConfig.services.desktopManager.gnome.enable) [ strata ];

  # “在文件管理器中显示”走 FileManager1，独立于目录 MIME 默认关联。
  # 包保留了带绝对 Exec 路径的可选模板；用户级服务优先于 profile 中的 Nautilus。
  xdg.dataFile."dbus-1/services/org.freedesktop.FileManager1.service" =
    lib.mkIf (!osConfig.services.desktopManager.gnome.enable) {
      source = "${strata}/share/strata/io.github.lgse.Strata.FileManager1.service";
    };
}
