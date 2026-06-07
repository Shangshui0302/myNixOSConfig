{ config, pkgs, inputs, ... }:

{
  imports = [
    ./noctalia.nix
    ./btop.nix
    ./hyprland.nix
    ./nvim.nix
    ./shell.nix
    ./yazi.nix
    ./onedrive.nix
    ./fonts-extra.nix
  ];

  ####################################
  #
  # User Applications
  #
  ####################################

  home.packages = with pkgs; [
    # Notes & Productivity
    obsidian btop gemini-cli
    vscode

    # Browser & Communication
    google-chrome qq telegram-desktop

    # Media
    netease-cloud-music-gtk obs-studio go-musicfox localsend

    # Office
    libreoffice libsForQt5.qt5ct

    # WeChat (scale fix)
    (wechat.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        wrapProgram $out/bin/wechat \
        --add-flags "--force-device-scale-factor=1.5"
      '';
    }))

    # WPS Office (scale fix)
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

  # CJK 字体回退：解决 Steam/WPS 等自备字体的应用找不到中文字形
  xdg.configFile."fontconfig/conf.d/10-cjk-fallback.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <alias>
        <family>sans-serif</family>
        <prefer>
          <family>WenQuanYi Micro Hei</family>
          <family>Noto Sans CJK SC</family>
          <family>WenQuanYi Zen Hei</family>
        </prefer>
      </alias>
      <alias>
        <family>serif</family>
        <prefer>
          <family>Noto Serif CJK SC</family>
        </prefer>
      </alias>
    </fontconfig>
  '';

  # 覆盖 nemo desktop：改显示名为 Nemo，图标用 system-file-manager
  xdg.desktopEntries.nemo = {
    name = "Nemo";
    icon = "nemo";
    exec = "nemo %F";
    type = "Application";
    categories = [ "System" "FileTools" "FileManager" "GTK" ];
    mimeType = [ "inode/directory" ];
    noDisplay = false;
  };

  # 深色模式 dconf 默认值（darkman 接管动态更新，Noctalia GTK 模板接管 CSS）
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "Papirus";
      gtk-application-prefer-dark-theme = true;
    };
    "org/nemo/preferences" = {
      show-image-thumbnails = "always";
      thumbnail-limit = 104857600;
    };
  };

  services.darkman = {
    enable = true;
    settings = {
      lat = 30.57;
      lng = 104.07;
    };
    darkModeScripts.dconf = ''
      DCONF="${pkgs.dconf}/bin/dconf"
      $DCONF write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
      $DCONF write /org/gnome/desktop/interface/gtk-theme "'adw-gtk3-dark'"
      $DCONF write /org/gnome/desktop/interface/gtk-application-prefer-dark-theme "true"
    '';
    darkModeScripts.qt5ct = ''
      mkdir -p ~/.config/qt5ct
      cat > ~/.config/qt5ct/qt5ct.conf << 'EOF'
      [Appearance]
      style=Fusion
      color_scheme=darker
      EOF
    '';
    lightModeScripts.dconf = ''
      DCONF="${pkgs.dconf}/bin/dconf"
      $DCONF write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
      $DCONF write /org/gnome/desktop/interface/gtk-theme "'adw-gtk3'"
      $DCONF write /org/gnome/desktop/interface/gtk-application-prefer-dark-theme "false"
    '';
    lightModeScripts.qt5ct = ''
      mkdir -p ~/.config/qt5ct
      cat > ~/.config/qt5ct/qt5ct.conf << 'EOF'
      [Appearance]
      style=Fusion
      EOF
    '';
  };

  # 告诉系统，HM 已经准备好接管了
  programs.home-manager.enable = true;
}
