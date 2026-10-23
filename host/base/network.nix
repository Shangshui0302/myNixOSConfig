{ config, lib, pkgs, ... }:

let
  gistSync = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);
  syncCommand = mode: lib.concatStringsSep " " [
    "${gistSync}/bin/python3"
    "${../mihomo-gist-sync.py}"
    mode
    "--template" "${../mihomo-config.yaml.in}"
    "--url-file" config.sops.secrets.mihomo_gist_url.path
    "--bootstrap" config.sops.secrets.mihomo_bootstrap.path
    "--state-dir" "/persist/secrets/mihomo-gist-state"
    "--mihomo" (lib.getExe config.services.mihomo.package)
  ];
in

{
  networking.hostName = "MechRevo-NixOS";
  networking.networkmanager.enable = true;

  # Advertise this host on the LAN so peer SSH configs can use
  # MechRevo-NixOS.local instead of a DHCP-dependent address.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

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

  systemd.services.mihomo = {
    requires = [ "mihomo-gist-seed.service" ];
    after = [ "mihomo-gist-seed.service" ];
  };

  systemd.services.mihomo.serviceConfig = {
    # PID 1 reads the root-only snapshot and hands a private credential to DynamicUser.
    LoadCredential = lib.mkForce [ "config.yaml:/persist/secrets/mihomo-gist-state/active.yaml" ];
    ExecStart = lib.mkForce (lib.concatStringsSep " " ([
      (lib.getExe config.services.mihomo.package)
      "-d" "/var/lib/private/mihomo"
      "-f" "\${CREDENTIALS_DIRECTORY}/config.yaml"
    ] ++ lib.optional (config.services.mihomo.webui != null) "-ext-ui ${config.services.mihomo.webui}"
    ));
  };

  # Only the root-run sync units read the sops-managed inputs.
  systemd.services.mihomo-gist-seed = {
    description = "Seed Mihomo from the bootstrap YAML or private Gist";
    after = [ "sops-install-secrets.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    requires = [ "sops-install-secrets.service" ];
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = "/run/secrets/mihomo_env";
      ExecStart = syncCommand "seed";
      UMask = "0077";
    };
  };

  systemd.services.mihomo-gist-update = {
    description = "Validate and update Mihomo from private Gist";
    after = [ "network-online.target" "sops-install-secrets.service" ];
    wants = [ "network-online.target" ];
    requires = [ "sops-install-secrets.service" ];
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = "/run/secrets/mihomo_env";
      ExecStart = syncCommand "update";
      UMask = "0077";
    };
  };

  systemd.timers.mihomo-gist-update = {
    description = "Refresh Mihomo Gist configuration every six hours";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "15min";
      OnUnitActiveSec = "6h";
      Persistent = true;
    };
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
