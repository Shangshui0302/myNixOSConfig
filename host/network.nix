{ config, lib, pkgs, ... }:

let
  # MetaCubeX MRS 规则文件：provider 名 → jsdelivr URL
  mrsProviders = {
    "geosite-cn" = "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/cn.mrs";
    "geosite-ads" = "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/category-ads-all.mrs";
    "geosite-geolocation-nocn" = "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/geolocation-!cn.mrs";
    "geoip-cn" = "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geoip/cn.mrs";
    "geosite-bilibili" = "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/bilibili.mrs";
    "geosite-bahamut" = "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/bahamut.mrs";
    "geosite-openai" = "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/openai.mrs";
    "geosite-netflix" = "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/netflix.mrs";
    "geosite-youtube" = "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/youtube.mrs";
    "geosite-google" = "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/google.mrs";
    "geosite-github" = "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/github.mrs";
    "geosite-microsoft" = "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/microsoft.mrs";
    "geosite-telegram" = "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/telegram.mrs";
    "geosite-apple" = "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/apple.mrs";
    "geosite-steam" = "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/steam.mrs";
    "geosite-cloudflare" = "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/cloudflare.mrs";
  };

  # curl 下载脚本：每个 provider 一行 "curl ... || true"（容错，不阻塞启动）
  downloadMRS = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: url:
    "${pkgs.curl}/bin/curl -sSL --max-time 60 --retry 2 -o /var/lib/private/mihomo/ruleset/${name}.mrs \"${url}\" || true"
  ) mrsProviders);

  # 下载 + API 热重载脚本（用于 timer）
  downloadAndReloadMRS = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: url: ''
    ${pkgs.curl}/bin/curl -sSL --max-time 60 --retry 2 -o /var/lib/private/mihomo/ruleset/${name}.mrs "${url}" || true
    ${pkgs.curl}/bin/curl -s -X PUT "http://127.0.0.1:9090/providers/rules/${name}" \
      -H "Authorization: Bearer $MIHOMO_SECRET" || true
  '') mrsProviders);
in
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

  # preStart：下载 MetaCubeX MRS 规则文件，渲染配置模板
  # 在 mihomo 启动前执行（此时无 TUN/DNS 劫持，网络直连可用）
  systemd.services.mihomo.preStart = ''
    mkdir -p /var/lib/private/mihomo/{providers,ruleset}
    ${downloadMRS}
    ${pkgs.envsubst}/bin/envsubst \
      -i ${./mihomo-config.yaml.in} \
      -o /run/mihomo/config.yaml
  '';

  # 每日 4:17 刷新 MRS 规则文件并通知 mihomo 热重载
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
      mkdir -p /var/lib/private/mihomo/ruleset
      ${downloadAndReloadMRS}
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