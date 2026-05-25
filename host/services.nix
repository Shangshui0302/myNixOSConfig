{ pkgs, ... }:

{
  ####################################
  #
  # Audio (PipeWire)
  #
  ####################################

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
  };

  ####################################
  #
  # Bluetooth
  #
  ####################################

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  ####################################
  #
  # Printing (CUPS)
  #
  ####################################

  services.printing.enable = true;

  ####################################
  #
  # Power Management
  #
  ####################################

  services.thermald.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  ####################################
  #
  # SSD
  #
  ####################################

  services.fstrim.enable = true;

  ####################################
  #
  # Proxy (Mihomo)
  #
  ####################################

  services.mihomo = {
    enable = true;
    configFile = "/persist/mihomo/config.yaml";
    tunMode = true;
    webui = pkgs.metacubexd;
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking.nftables.enable = true;

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "Meta" ];
    checkReversePath = "loose";
  };

  ####################################
  #
  # Other Services
  #
  ####################################

  services.gvfs.enable = true;

  services.udev.packages = [
    pkgs.stlink
    pkgs.openocd
  ];
}
