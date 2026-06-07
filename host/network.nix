{ pkgs, ... }:

{
  networking.hostName = "MechRevo-NixOS";
  networking.networkmanager.enable = true;

  # Mihomo proxy (TUN mode)
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

  environment.systemPackages = with pkgs; [
    dnsutils iputils tcpdump mtr nmap iperf3 ethtool iptables
  ];
}
