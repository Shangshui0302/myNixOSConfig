{ config, lib, pkgs, ... }:

let
  stateDir = "/var/lib/mihomo-config";
  python = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);
  syncCommand = mode: lib.escapeShellArgs ([
    "${python}/bin/python3"
    "${../mihomo-config-sync.py}"
    mode
    "--template" "${../mihomo-config.yaml.in}"
    "--state-dir" stateDir
    "--mihomo" (lib.getExe config.services.mihomo.package)
  ] ++ (if mode == "seed" then [
    "--bootstrap" config.sops.secrets.mihomo_bootstrap.path
  ] else [
    "--sub-store-url"
    "http://127.0.0.1:3001/backend/api/file/dual-provider-mihomo?noCache=true"
  ]));
  syncServiceConfig = {
    Type = "oneshot";
    EnvironmentFile = config.sops.secrets.mihomo_env.path;
    StateDirectory = "mihomo-config";
    StateDirectoryMode = "0700";
    UMask = "0077";
    TimeoutStartSec = "10min";
  };
in
{
  services.mihomo = {
    enable = true;
    # An absolute string is a runtime path, not a file copied to the Nix store.
    # The native module loads this file as a credential for DynamicUser.
    configFile = "${stateDir}/active.yaml";
    tunMode = true;
    webui = pkgs.zashboard;
  };

  systemd.services.mihomo = {
    requires = [ "mihomo-config-seed.service" ];
    after = [ "mihomo-config-seed.service" ];
    restartTriggers = [ ../mihomo-config.yaml.in ];
  };

  systemd.services.mihomo-config-seed = {
    description = "Prepare Mihomo from its last validated snapshot or bootstrap";
    after = [ "sops-install-secrets.service" ];
    requires = [ "sops-install-secrets.service" ];
    serviceConfig = syncServiceConfig // {
      ExecStart = syncCommand "seed";
    };
  };

  systemd.services.mihomo-config-update = {
    description = "Generate and validate Mihomo configuration from local Sub-Store";
    # Boot from the snapshot first; generating fresh data may need that proxy.
    after = [ "network-online.target" "sops-install-secrets.service" "sub-store.service" "mihomo.service" ];
    wants = [ "network-online.target" "sub-store.service" ];
    requires = [ "sops-install-secrets.service" ];
    serviceConfig = syncServiceConfig // {
      ExecStart = syncCommand "update";
    };
  };

  systemd.timers.mihomo-config-update = {
    description = "Refresh Mihomo from local Sub-Store every six hours";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "15min";
      OnUnitActiveSec = "6h";
    };
  };
}
