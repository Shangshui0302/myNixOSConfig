{ config, pkgs, ... }:

{
  imports = [
    ./noctalia.nix
  ];
  
  # 必填：用户名和家目录路径
  home.username = "lishangshui";
  home.homeDirectory = "/home/lishangshui";

  # 必填：HM 版本号，建议与系统版本对应
  home.stateVersion = "25.11"; # 或者你当前的稳定版本

  # 这里放置你想安装的用户级软件
  home.packages = with pkgs; [
    fastfetch
    htop
    git
  ];
  
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    hyprcursor.enable = true;
    gtk.enable = true;
  };  

  programs.git = {
    enable = true;
    settings.user.name = "Li Shangshui";
    settings.user.email = "yomuwaterray@gmail.com";
  };

  programs.zellij = {
    enable = true;
    settings = {
      theme = "catppuccin-mocha";
    };
  };
  # 让 HM 自动管理你的 shell (比如 bash 或 zsh)
  programs.bash.enable = true;

  # 告诉系统，HM 已经准备好接管了
  programs.home-manager.enable = true;
}
