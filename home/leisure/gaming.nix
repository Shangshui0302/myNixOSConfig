{ pkgs, ... }: {
  home.packages = with pkgs; [
    heroic
    protonup-qt
    mangohud
  ];

  services.flatpak.packages = [
    "com.usebottles.bottles"
  ];
}
