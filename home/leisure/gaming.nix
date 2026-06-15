{ pkgs, ... }: {
  home.packages = with pkgs; [
    bottles
    heroic
    protonup-qt
    mangohud
  ];
}
