{ pkgs, ... }:

{
  networking.hostName = "MechRevo-NixOS";
  networking.networkmanager.enable = true;

  # Advertise this host on the LAN so peer SSH configs can use
  # MechRevo-NixOS.local instead of a DHCP-dependent address.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    settings.publish = {
      "disable-publishing" = false;
      "publish-addresses" = true;
    };
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
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
    allowedTCPPorts = [ 53317 8787 22 8788 18788];
    allowedUDPPorts = [ 53317 37991 ];
  };

  environment.systemPackages = with pkgs; [
    dnsutils iputils tcpdump mtr nmap iperf3 ethtool iptables
  ];
}
