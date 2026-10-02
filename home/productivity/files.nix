{ pkgs, ... }:

let
  # nixpkgs 尚无 Strata，从本地包引入；构建入口 nix build path:.#strata。
  strata = import ../../local-deriv/strata.nix { inherit pkgs; };
in
{
  # 文件管理器：主 DE 与 GNOME 共同提供 Nautilus/Sushi，另保留 Dolphin 与 Strata。
  home.packages = with pkgs; [
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
    strata
  ];

}
