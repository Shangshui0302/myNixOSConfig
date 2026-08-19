{ pkgs, ... }: {
  home.packages = with pkgs; [
    mangohud
    virt-manager
  ];

}
