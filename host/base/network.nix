{ config, lib, pkgs, ... }:

{
  networking.hostName = "MechRevo-NixOS";
  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  # Mihomo proxy (TUN mode)
  services.mihomo = {
    enable = true;
    configFile = ../mihomo-config.yaml.in;
    tunMode = true;
    webui = pkgs.zashboard;
  };

  # preStart：渲染配置模板
  systemd.services.mihomo.preStart = ''
    mkdir -p /var/lib/private/mihomo/{providers,ruleset}
    ${pkgs.envsubst}/bin/envsubst \
      -i ${../mihomo-config.yaml.in} \
      -o /run/mihomo/config.yaml
  '';


  systemd.services.mihomo = {
    after = [ "sops-install-secrets.service" ];
    wants = [ "sops-install-secrets.service" ];
  };

  systemd.services.mihomo.serviceConfig = {
    EnvironmentFile = "/run/secrets/mihomo_env";
    RuntimeDirectory = "mihomo";
    ExecStart = lib.mkForce (lib.concatStringsSep " " ([
      (lib.getExe config.services.mihomo.package)
      "-d" "/var/lib/private/mihomo"
      "-f" "/run/mihomo/config.yaml"
    ] ++ lib.optional (config.services.mihomo.webui != null) "-ext-ui ${config.services.mihomo.webui}"
    ));
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
    allowedTCPPorts = [ 53317 ];
    allowedUDPPorts = [ 53317 ];
  };

  environment.systemPackages = with pkgs; [
    dnsutils iputils tcpdump mtr nmap iperf3 ethtool iptables
  ];
}