{ pkgs, ... }:

{
  home.packages = [
    # 苹方 (PingFang) — Apple 系统字体，OTF 提取版
    (pkgs.stdenv.mkDerivation {
      name = "pingfang-otf";
      src = pkgs.fetchzip {
        url = "https://github.com/jimmyctk/PingFang-OTF-Fonts/archive/main.tar.gz";
        sha256 = "sha256-DeZT802/7y939XT+upaFmEGlp6+vIgCpKbo12HEiGKc=";
      };
      installPhase = ''
        mkdir -p $out/share/fonts/opentype
        cp $src/OTF/*.otf $out/share/fonts/opentype/
      '';
    })

    # HarmonyOS Sans — 华为鸿蒙开源字体
    (pkgs.stdenv.mkDerivation {
      name = "harmonyos-sans";
      src = pkgs.fetchzip {
        url = "https://github.com/ajacocks/harmonyos-sans-font/archive/main.tar.gz";
        sha256 = "sha256-b29XpkGkwIp+LjBOSQfv/gUCKm6nKSv/rJ1GYwI4PdA=";
      };
      installPhase = ''
        mkdir -p $out/share/fonts/truetype
        find $src -name "*.ttf" -exec cp {} $out/share/fonts/truetype/ \;
      '';
    })
  ];
}
