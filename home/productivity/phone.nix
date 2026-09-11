{ pkgs, ... }:

{
  # Android discovery/control and SFTP mounting for phone integration.
  # KDE Connect itself and its firewall ports are owned by host/base/desktop.nix.
  home.packages = with pkgs; [
    android-tools
    scrcpy
    sshfs
  ];
}
