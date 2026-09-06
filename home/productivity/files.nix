{ pkgs, ... }:

{
  # 文件管理器：主 DE 与 GNOME 共同提供 Nautilus/Sushi，另保留 Dolphin。
  home.packages = with pkgs; [
    ouch
    p7zip
    unzip
    file-roller
    nautilus
    sushi
    ffmpegthumbnailer
    tumbler
    kdePackages.dolphin
  ];

}
