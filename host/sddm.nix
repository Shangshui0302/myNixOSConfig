{ pkgs, ... }:

let
  wallpaper = ../assets/yamadaryou.png;
  sddm-custom-theme = pkgs.stdenv.mkDerivation {
    name = "sddm-astronaut-custom";
    src = pkgs.sddm-astronaut;
    installPhase = ''
      theme=$src/share/sddm/themes/sddm-astronaut-theme
      mkdir -p $out/share/sddm/themes/custom
      cp -r $theme/* $out/share/sddm/themes/custom/
      chmod -R +w $out/share/sddm/themes/custom/
      cp ${wallpaper} $out/share/sddm/themes/custom/Backgrounds/wallpaper.png
      sed -i \
        -e 's|^ScreenWidth=.*|ScreenWidth=""|' \
        -e 's|^ScreenHeight=.*|ScreenHeight=""|' \
        -e 's|^Font=.*|Font="JetBrains Mono"|' \
        -e 's|^FontSize=.*|FontSize="12"|' \
        -e 's|^RoundCorners=.*|RoundCorners="12"|' \
        -e 's|^Background=.*|Background="Backgrounds/wallpaper.png"|' \
        -e 's|^DimBackground=.*|DimBackground="0.25"|' \
        -e 's|^FormBackgroundColor=.*|FormBackgroundColor="#1a1b26"|' \
        -e 's|^BackgroundColor=.*|BackgroundColor="#1a1b26"|' \
        -e 's|^DimBackgroundColor=.*|DimBackgroundColor="#000000"|' \
        -e 's|^LoginFieldBackgroundColor=.*|LoginFieldBackgroundColor="#24253a"|' \
        -e 's|^PasswordFieldBackgroundColor=.*|PasswordFieldBackgroundColor="#24253a"|' \
        -e 's|^PlaceholderTextColor=.*|PlaceholderTextColor="#888888"|' \
        -e 's|^WarningColor=.*|WarningColor="#f7768e"|' \
        -e 's|^LoginButtonBackgroundColor=.*|LoginButtonBackgroundColor="#7aa2f7"|' \
        -e 's|^SystemButtonsIconsColor=.*|SystemButtonsIconsColor="#cccccc"|' \
        -e 's|^SessionButtonTextColor=.*|SessionButtonTextColor="#cccccc"|' \
        -e 's|^VirtualKeyboardButtonTextColor=.*|VirtualKeyboardButtonTextColor="#cccccc"|' \
        -e 's|^UserIconColor=.*|UserIconColor="#7aa2f7"|' \
        -e 's|^PasswordIconColor=.*|PasswordIconColor="#7aa2f7"|' \
        -e 's|^HoverUserIconColor=.*|HoverUserIconColor="#89b4fa"|' \
        -e 's|^HoverPasswordIconColor=.*|HoverPasswordIconColor="#89b4fa"|' \
        -e 's|^HoverSystemButtonsIconsColor=.*|HoverSystemButtonsIconsColor="#89b4fa"|' \
        -e 's|^HoverSessionButtonTextColor=.*|HoverSessionButtonTextColor="#89b4fa"|' \
        -e 's|^HoverVirtualKeyboardButtonTextColor=.*|HoverVirtualKeyboardButtonTextColor="#89b4fa"|' \
        -e 's|^HighlightTextColor=.*|HighlightTextColor="#89b4fa"|' \
        -e 's|^HighlightBackgroundColor=.*|HighlightBackgroundColor="#24253a"|' \
        -e 's|^HighlightBorderColor=.*|HighlightBorderColor="#7aa2f7"|' \
        -e 's|^PartialBlur=.*|PartialBlur="true"|' \
        -e 's|^FullBlur=.*|FullBlur="false"|' \
        -e 's|^BlurMax=.*|BlurMax="64"|' \
        -e 's|^Blur=.*|Blur="1.5"|' \
        -e 's|^FormPosition=.*|FormPosition="left"|' \
        -e 's|^BypassSystemButtonsChecks=.*|BypassSystemButtonsChecks="true"|' \
        -e 's|^HideSystemButtons=.*|HideSystemButtons="false"|' \
        $out/share/sddm/themes/custom/Themes/astronaut.conf
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
