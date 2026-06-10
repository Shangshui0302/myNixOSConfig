{ config, lib, pkgs, ... }:

{
  networking.hostName = "MechRevo-NixOS";
  networking.networkmanager.enable = true;

  # Mihomo proxy (TUN mode)
  services.mihomo = {
    enable = true;
    configFile = ./mihomo-config.yaml.in;
    tunMode = true;
    webui = pkgs.zashboard;
  };

  # preStart 在 mihomo 启动前执行（此时 TUN 未接管，系统 DNS 正常）
  # 1. 下载订阅，拆分出 proxies 和 rules
  # 2. envsubst 替换模板中的 ${VAR} 占位符
  systemd.services.mihomo.preStart = ''
    mkdir -p /var/lib/private/mihomo/providers
    ${pkgs.curl}/bin/curl -sL --max-time 30 "$MIHOMO_SUBSCRIPTION_URL" \
      | ${pkgs.gawk}/bin/awk '
        /^rules:/   { in_rules=1; next }
        in_rules && /^  - / { sub(/^  - /, ""); print }
        in_rules && !/^  - / { exit }
      ' > /var/lib/private/mihomo/providers/rules.yaml
    ${pkgs.curl}/bin/curl -sL --max-time 30 \
      -o /var/lib/private/mihomo/providers/proxies.yaml \
      "$MIHOMO_SUBSCRIPTION_URL"
    ${pkgs.envsubst}/bin/envsubst \
      -i ${./mihomo-config.yaml.in} \
      -o /run/mihomo/config.yaml
  '';

  systemd.services.mihomo.serviceConfig = {
    EnvironmentFile = "/persist/secrets/mihomo.env";
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
