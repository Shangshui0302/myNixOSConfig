{ pkgs, ... }: {
  home.packages = with pkgs; [
    heroic
    protonup-qt
    mangohud
  ];
}
