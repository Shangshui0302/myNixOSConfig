{ config, pkgs, ... }:

{
  # Pointer cursor
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    hyprcursor.enable = true;
    gtk.enable = true;
  };

  # CJK font fallback
  xdg.configFile."fontconfig/conf.d/10-cjk-fallback.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <alias>
        <family>sans-serif</family>
        <prefer>
          <family>WenQuanYi Micro Hei</family>
          <family>Noto Sans CJK SC</family>
          <family>WenQuanYi Zen Hei</family>
        </prefer>
      </alias>
      <alias>
        <family>serif</family>
        <prefer>
          <family>Noto Serif CJK SC</family>
        </prefer>
      </alias>
    </fontconfig>
  '';

  # Extra fonts & Qt5 theme
  home.packages = with pkgs; [
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
    libsForQt5.qt5ct
    papirus-icon-theme gnome-themes-extra adw-gtk3
  ];

  # Dark mode defaults
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "Papirus";
      gtk-application-prefer-dark-theme = true;
    };
    "org/nemo/preferences" = {
      show-image-thumbnails = "always";
      thumbnail-limit = 104857600;
    };
  };

}
