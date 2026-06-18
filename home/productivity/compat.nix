{ pkgs, ... }: {
  home.packages = with pkgs; [
    wineWow64Packages.stable
    winetricks
    virt-manager
  ];

  services.flatpak.packages = [
    "com.usebottles.bottles"
  ];
}
