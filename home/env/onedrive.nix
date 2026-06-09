{ pkgs, ... }:

{
  programs.onedrive = {
    enable = true;
    settings = {
      sync_dir = "~/OneDrive";
      check_nomount = "false";
      check_nosync = "false";
      skip_dotfiles = "false";
      cleanup_local_files = "false";
      no_remote_delete = "false";
    };
  };

  xdg.configFile."onedrive/sync_list".text = ''
    1_Inbox
    4_Bookshelf
    6_Personal
    7_MediaLibrary
    图片
    Videos
  '';

  systemd.user.services.onedrive = {
    Unit = {
      Description = "OneDrive Sync Service";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      ExecStart = "${pkgs.onedrive}/bin/onedrive --monitor";
      Restart = "on-failure";
      RestartSec = 10;
      TimeoutStopSec = 15;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
