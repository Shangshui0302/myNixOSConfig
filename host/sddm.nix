{ pkgs, ... }:

let
  wallpaper = ../assets/wallpaper.png;
  sddm-custom-theme = pkgs.stdenv.mkDerivation {
    name = "sddm-astronaut-custom";
    src = pkgs.sddm-astronaut;
    installPhase = ''
      theme=$src/share/sddm/themes/sddm-astronaut-theme
      mkdir -p $out/share/sddm/themes/custom
      cp -r $theme/* $out/share/sddm/themes/custom/
      chmod -R +w $out/share/sddm/themes/custom/
      cp ${wallpaper} $out/share/sddm/themes/custom/Backgrounds/wallpaper.png
      cat > $out/share/sddm/themes/custom/theme.conf.user << 'CONF'
      [General]
      Font="JetBrains Mono"
      FontSize="12"
      RoundCorners="12"

      [Background]
      Background="Backgrounds/wallpaper.png"
      DimBackground="0.25"

      [Colors]
      LoginButtonBackgroundColor="#7aa2f7"
      UserIconColor="#7aa2f7"
      PasswordIconColor="#7aa2f7"
      HoverUserIconColor="#89b4fa"
      HoverPasswordIconColor="#89b4fa"

      [Form]
      FullBlur="true"
      BlurMax="64"
      Blur="1.5"
      FormPosition="center"
      CONF
    '';
  };
in
{
  environment.systemPackages = [ sddm-custom-theme ];

  services.displayManager.sddm = {
    enable = true;
    theme = "custom";
    extraPackages = with pkgs.qt6; [ qtmultimedia ];
  };
}
