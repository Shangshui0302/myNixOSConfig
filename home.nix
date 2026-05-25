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

  home.packages = with pkgs; [
    # Terminal & Shell
    starship
    eza
    zoxide
    fzf
    bat
    fd

    # Dev toolchain
    nodejs_24
    gcc
    tree

    # Hyprland 生态
    swww
    swaynotificationcenter
    libnotify
    grim
    slurp
    wl-clipboard
    kitty
    waybar
    wofi

    # 日常软件
    obsidian
    btop
    gemini-cli
    fastfetch
    ghostty
    vscode
    vimPlugins.nvchad
    google-chrome
    qq
    telegram-desktop

    # 媒体 & 工具
    claude-code
    netease-cloud-music-gtk
    go-musicfox
    localsend
    (wechat.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        wrapProgram $out/bin/wechat \
        --add-flags "--force-device-scale-factor=1.5"
      '';
    }))
    wpsoffice
    libreoffice

    steam-run
    htop
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
  programs.bash = {
    enable = true;
    initExtra = ''
      # Starship prompt
      eval "$(starship init bash)"

      # zoxide 智能 cd
      eval "$(zoxide init bash)"

      # 别名
      alias ls='eza --icons=auto'
      alias ll='eza -l --icons=auto'
      alias la='eza -la --icons=auto'
      alias lt='eza -T --icons=auto'
      alias cat='bat'
      alias grep='rg'
      alias find='fd'
      alias top='btop'
      alias tree='eza -T --icons=auto'
    '';
  };

  # 告诉系统，HM 已经准备好接管了
  programs.home-manager.enable = true;
}
