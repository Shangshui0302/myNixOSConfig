{ lib, pkgs, ... }:

{
  users.groups.sub-store = { };
  users.users.sub-store = {
    isSystemUser = true;
    group = "sub-store";
    home = "/var/lib/sub-store";
  };

  systemd.services.sub-store = {
    description = "Sub-Store subscription editor and publisher";
    documentation = [ "http://127.0.0.1:3001/?magicpath=backend" ];
    aliases = [ "substore.service" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      SUB_STORE_BACKEND_API_HOST = "127.0.0.1";
      SUB_STORE_BACKEND_API_PORT = "3001";
      SUB_STORE_BACKEND_MERGE = "1";
      SUB_STORE_FRONTEND_PATH = "${pkgs.sub-store-frontend}";
      SUB_STORE_FRONTEND_BACKEND_PATH = "/backend";
      SUB_STORE_DATA_BASE_PATH = "/var/lib/sub-store";
      SUB_STORE_CORS_ALLOWED_ORIGINS = "http://127.0.0.1:3001,http://localhost:3001";
      # Schedules belong to Sub-Store's data. No extra global publish/backup cron.
    };

    serviceConfig = {
      ExecStart = lib.getExe pkgs.sub-store;
      User = "sub-store";
      Group = "sub-store";
      WorkingDirectory = "/var/lib/sub-store";
      StateDirectory = "sub-store";
      StateDirectoryMode = "0700";
      UMask = "0077";
      Restart = "on-failure";
      RestartSec = "5s";
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
      CapabilityBoundingSet = "";
    };
  };
}
