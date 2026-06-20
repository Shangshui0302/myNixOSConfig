{ pkgs, ... }: {
  home.packages = with pkgs; [
    wineWow64Packages.stable
    winetricks
    virt-manager
  ];

  services.flatpak.packages = [
    "com.usebottles.bottles"
    "com.github.tchx84.Flatseal"
  ];

  services.flatpak.overrides = {
    "com.usebottles.bottles" = {
      Context = {
        sockets = [
          "wayland"
          "fallback-x11"
          "pulseaudio"
          "system-bus"
        ];
        devices = [ "all" ];
        filesystems = [
          "~/Downloads:rw"
          "~/.local/share/applications:rw"
          "~/Games:rw"
          # "/mnt/Games:rw"
          "~/.local/share/bottles:rw"
          "/usr/share/fonts:ro"
        ];
      };
      Environment = {
        QT_IM_MODULE = "fcitx";
        GTK_IM_MODULE = "fcitx";
        XMODIFIERS = "@im=fcitx";
      };
    };
  };
}
