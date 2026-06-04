{ pkgs, ... }:

let
  wallpaper = ../assets/wallpaper.png;
  sddm-custom-theme = pkgs.stdenv.mkDerivation {
    name = "sddm-astronaut-custom";
    src = pkgs.sddm-astronaut;
    installPhase = ''
      mkdir -p $out/share/sddm/themes/custom
      cp -r $src/share/sddm/themes/sddm-astronaut-theme/* $out/share/sddm/themes/custom/
      chmod -R +w $out/share/sddm/themes/custom/
      cp ${wallpaper} $out/share/sddm/themes/custom/Backgrounds/wallpaper.png
      cat > $out/share/sddm/themes/custom/Themes/astronaut.conf << 'CONF'
      [General]
      ScreenWidth=""
      ScreenHeight=""
      Font="JetBrains Mono"
      FontSize="12"
      RoundCorners="12"
      HeaderText=""

      [Background]
      Background="Backgrounds/wallpaper.png"
      CropBackground="true"
      DimBackground="0.25"

      [Colors]
      HeaderTextColor="#ffffff"
      DateTextColor="#dddddd"
      TimeTextColor="#ffffff"
      FormBackgroundColor="#1a1b26"
      BackgroundColor="#1a1b26"
      DimBackgroundColor="#000000"
      LoginFieldBackgroundColor="#24253a"
      PasswordFieldBackgroundColor="#24253a"
      LoginFieldTextColor="#ffffff"
      PasswordFieldTextColor="#ffffff"
      UserIconColor="#7aa2f7"
      PasswordIconColor="#7aa2f7"
      PlaceholderTextColor="#888888"
      WarningColor="#f7768e"
      LoginButtonTextColor="#ffffff"
      LoginButtonBackgroundColor="#7aa2f7"
      SystemButtonsIconsColor="#cccccc"
      SessionButtonTextColor="#cccccc"
      VirtualKeyboardButtonTextColor="#cccccc"
      HoverUserIconColor="#89b4fa"
      HoverPasswordIconColor="#89b4fa"
      HoverSystemButtonsIconsColor="#89b4fa"
      HoverSessionButtonTextColor="#89b4fa"
      HoverVirtualKeyboardButtonTextColor="#89b4fa"
      HighlightTextColor="#89b4fa"
      HighlightBackgroundColor="#24253a"
      HighlightBorderColor="#7aa2f7"

      [Form]
      PartialBlur="false"
      FullBlur="true"
      BlurMax="64"
      Blur="1.5"
      HaveFormBackground="false"
      FormPosition="center"

      [Interface]
      ForceLastUser="true"
      PasswordFocus="true"
      HideCompletePassword="true"
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
