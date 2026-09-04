{ pkgs, ... }: {
  # Steam 游戏平台（32bit 图形栈在 hardware.nix，虚拟化在 virtualization.nix）。
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
  };
}
