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

  services.darkman = {
    enable = true;
    settings = {
      lat = 30.57;
      lng = 104.07;
    };
    darkModeScripts.dconf = ''
      DCONF="${pkgs.dconf}/bin/dconf"
      $DCONF write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
      $DCONF write /org/gnome/desktop/interface/gtk-theme "'adw-gtk3-dark'"
      $DCONF write /org/gnome/desktop/interface/gtk-application-prefer-dark-theme "true"
    '';
    darkModeScripts.qt5ct = ''
      mkdir -p ~/.config/qt5ct
      cat > ~/.config/qt5ct/qt5ct.conf << 'EOF'
      [Appearance]
      style=Fusion
      color_scheme=darker
      EOF
    '';
    lightModeScripts.dconf = ''
      DCONF="${pkgs.dconf}/bin/dconf"
      $DCONF write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
      $DCONF write /org/gnome/desktop/interface/gtk-theme "'adw-gtk3'"
      $DCONF write /org/gnome/desktop/interface/gtk-application-prefer-dark-theme "false"
    '';
    lightModeScripts.qt5ct = ''
      mkdir -p ~/.config/qt5ct
      cat > ~/.config/qt5ct/qt5ct.conf << 'EOF'
      [Appearance]
      style=Fusion
      EOF
    '';
  };
}
