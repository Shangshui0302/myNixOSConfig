{ config, pkgs, inputs, ... }:

{
  imports = [
    ./noctalia.nix
    ./btop.nix
    ./hyprland.nix
    ./packages.nix
    ./shell.nix
    ./yazi.nix
    ./onedrive.nix
  ];

  # 必填：用户名和家目录路径
  home.username = "lishangshui";
  home.homeDirectory = "/home/lishangshui";

  # 必填：HM 版本号，建议与系统版本对应
  home.stateVersion = "25.11";

  # 指针光标
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    hyprcursor.enable = true;
    gtk.enable = true;
  };

  # Git 配置
  programs.git = {
    enable = true;
    settings.user.name = "Li Shangshui";
    settings.user.email = "yomuwaterray@gmail.com";
    ignores = [ "**/.claude/settings.local.json" ];
  };

  # 告诉系统，HM 已经准备好接管了
  programs.home-manager.enable = true;
}
