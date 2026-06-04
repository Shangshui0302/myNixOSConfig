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
    (pkgs.symlinkJoin {
      name = "wpsoffice-wrapped";
      paths = [ pkgs.wpsoffice ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        for bin in wps wpp et wpspdf; do
          wrapProgram $out/bin/$bin \
            --set QT_SCALE_FACTOR 2 \
            --set QT_AUTO_SCREEN_SCALE_FACTOR 0
        done
        for desktop in $out/share/applications/wps-office-*.desktop; do
          name=$(basename "$desktop")
          rm "$desktop"
          cp "${pkgs.wpsoffice}/share/applications/$name" "$desktop"
          substituteInPlace "$desktop" \
            --replace-fail '${pkgs.wpsoffice}' "$out"
        done
      '';
    })
    libreoffice
    libsForQt5.qt5ct

    steam-run
    htop
  ];
}
