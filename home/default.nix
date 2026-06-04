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
    ./fonts-extra.nix
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

  # 深色模式 dconf 默认值（darkman 接管动态更新）
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
      icon-theme = "Papirus";
      gtk-application-prefer-dark-theme = true;
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
      $DCONF write /org/gnome/desktop/interface/gtk-theme "'Adwaita-dark'"
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
      $DCONF write /org/gnome/desktop/interface/gtk-theme "'Adwaita'"
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
