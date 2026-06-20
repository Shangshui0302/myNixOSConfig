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

  # preStart：下载订阅，提取 rules，渲染模板
  # proxies 由 proxy-providers (type: http, interval: 86400) 自行拉取
  systemd.services.mihomo.preStart = ''
    set -e
    source /persist/secrets/mihomo.env
    mkdir -p /var/lib/private/mihomo/providers
    ${pkgs.curl}/bin/curl -sL --max-time 30 "$MIHOMO_SUBSCRIPTION_URL" \
      | ${pkgs.gawk}/bin/awk '
        /^rules:/   { in_rules=1; next }
        in_rules && /^ - / { sub(/^ - /, ""); print }
        in_rules && !/^ - / { exit }
      ' > /var/lib/private/mihomo/providers/rules.yaml
    ${pkgs.envsubst}/bin/envsubst \
      -i ${./mihomo-config.yaml.in} \
      -o /run/mihomo/config.yaml
  '';

  # 每日 4:17 刷新规则文件 + 通知 mihomo 重载
  systemd.timers.mihomo-rule-refresh = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:17:00";
      RandomizedDelaySec = 300;
      Persistent = true;
    };
  };
  systemd.services.mihomo-rule-refresh = {
    serviceConfig.Type = "oneshot";
    script = ''
      set -e
      source /persist/secrets/mihomo.env
      mkdir -p /var/lib/private/mihomo/providers
      ${pkgs.curl}/bin/curl -sL --max-time 30 "$MIHOMO_SUBSCRIPTION_URL" \
        | ${pkgs.gawk}/bin/awk '
          /^rules:/   { in_rules=1; next }
          in_rules && /^ - / { sub(/^ - /, ""); print }
          in_rules && !/^ - / { exit }
        ' > /var/lib/private/mihomo/providers/rules.yaml
      ${pkgs.curl}/bin/curl -s -X PUT http://127.0.0.1:9090/providers/rules/sub-rules \
        -H "Authorization: Bearer $MIHOMO_SECRET" || true
    '';
    after = [ "mihomo.service" ];
    requires = [ "mihomo.service" ];
  };

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
