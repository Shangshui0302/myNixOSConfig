{ pkgs, ... }:

{
  programs.onedrive = {
    enable = true;
    settings = {
      sync_dir = "~/OneDrive";
      check_nomount = "false";
      check_nosync = "false";
      skip_dotfiles = "false";
      skip_dir = "3_SchoolWork|Microsoft Edge Drop Files";
      skip_symlinks = "true";
      skip_file = "~*|.~*|*.tmp|*.swp|*.partial";
      cleanup_local_files = "false";
      no_remote_delete = "false";
      force_session_upload = "true";
      delay_inotify_processing = "true";
      use_recycle_bin = "true";
      space_reservation = "100";
    };
  };

  xdg.configFile."onedrive/sync_list".text = ''
    /1_Inbox/
    /4_Bookshelf/
    /6_Personal/
    /7_MediaLibrary/
    /图片/
    /Pictures/
    /Videos/
  '';

  # programs.onedrive only manages ~/.config/onedrive/config;
  # it does NOT create a systemd user service. The manual service
  # below is required for onedrive to auto-start on login.
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
