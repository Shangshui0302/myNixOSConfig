{ pkgs, ... }:

{
  # 主 DE 文件管理（nautilus/sushi 在 home/gnome.nix，GNOME 变体专属）。
  home.packages = with pkgs; [
    ouch
    p7zip
    unzip
    file-roller
    ffmpegthumbnailer
    tumbler
    kdePackages.dolphin
  ];

}
