{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Terminal & Shell
    starship
    eza
    zoxide
    fzf
    bat
    fd
    blesh

    # Dev toolchain
    nodejs_24
    gcc
    tree
    gh

    # Hyprland 生态
    awww
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
    codex
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
    libsForQt5.qt5ct

    steam-run
    htop
  ];
}
