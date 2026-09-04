{ pkgs, ... }:
{
  # Shell 域入口：包、别名、programs 配置、补全注册。
  # 桌面/应用专属补全在各自消费者模块（de/hyprland、de/niri、de/noctalia、leisure/player）。
  imports = [
    ./programs.nix
    ./completions.nix
  ];

  home.packages = with pkgs; [
    fzf bat fd blesh
  ];

  home.shellAliases = {
    cat = "bat";
    grep = "rg";
    find = "fd";
    top = "btop";
    tree = "eza --tree --icons=auto";
    snvim = "sudo HOME=$HOME XDG_CONFIG_HOME=$XDG_CONFIG_HOME XDG_DATA_HOME=$XDG_DATA_HOME nvim";
  };
}
