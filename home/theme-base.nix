{ config, pkgs, ... }:

{
  # 共享主题基础（两 DE）：指针光标、字体、图标主题、深浅色。
  # gtk-theme 各 DE 自行设置（主 DE 在 theme-de.nix，GNOME 在 specialisation/gnome）。

  # Pointer cursor
  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    hyprcursor.enable = true;
    gtk.enable = true;
  };

  # MS CJK font aliases with native-first fallback chains.
  # When native MS fonts are installed (via home.activation → ~/.local/share/fonts/MS/),
  # fontconfig resolves to the real font. When not installed, falls back to open-source
  # alternatives that were configured during evaluation.
  xdg.configFile."fontconfig/conf.d/20-ms-office-cjk.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <!-- Serif -->
      <alias><family>SimSun</family>
        <prefer><family>SimSun</family><family>Noto Serif CJK SC</family></prefer></alias>
      <alias><family>NSimSun</family>
        <prefer><family>NSimSun</family><family>Noto Serif CJK SC</family></prefer></alias>
      <alias><family>宋体</family>
        <prefer><family>SimSun</family><family>Noto Serif CJK SC</family></prefer></alias>

      <!-- Sans -->
      <alias><family>SimHei</family>
        <prefer><family>SimHei</family><family>Noto Sans CJK SC</family></prefer></alias>
      <alias><family>Microsoft YaHei</family>
        <prefer><family>Microsoft YaHei</family><family>Noto Sans CJK SC</family></prefer></alias>
      <alias><family>微软雅黑</family>
        <prefer><family>Microsoft YaHei</family><family>Noto Sans CJK SC</family></prefer></alias>
      <alias><family>黑体</family>
        <prefer><family>SimHei</family><family>Noto Sans CJK SC</family></prefer></alias>

      <!-- Kai -->
      <alias><family>KaiTi</family>
        <prefer><family>KaiTi</family><family>AR PL UKai CN</family></prefer></alias>
      <alias><family>楷体</family>
        <prefer><family>KaiTi</family><family>AR PL UKai CN</family></prefer></alias>

      <!-- FangSong -->
      <alias><family>FangSong</family>
        <prefer><family>FangSong</family><family>AR PL UMing CN</family></prefer></alias>
      <alias><family>仿宋</family>
        <prefer><family>FangSong</family><family>AR PL UMing CN</family></prefer></alias>

      <!-- Serif (Latin) -->
      <alias><family>Times New Roman</family>
        <prefer><family>Times New Roman</family><family>Noto Serif CJK SC</family></prefer></alias>

      <!-- DengXian -->
      <alias><family>DengXian</family>
        <prefer><family>DengXian</family><family>Noto Sans CJK SC</family></prefer></alias>
      <alias><family>等线</family>
        <prefer><family>DengXian</family><family>Noto Sans CJK SC</family></prefer></alias>
    </fontconfig>
  '';

  # Default font families — Anthropic fonts for Latin, Source Han Serif for CJK.
  # Anthropic Mono Variable for terminal/code.
  # Times New Roman covers Latin glyphs; Source Han Serif covers CJK.
  xdg.configFile."fontconfig/conf.d/30-default-fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <!-- Sans-serif (UI, apps) -->
      <match target="pattern">
        <test name="family"><string>sans-serif</string></test>
        <edit name="family" mode="prepend" binding="strong">
          <string>Anthropic Sans Web Text</string>
          <string>Source Han Serif</string>
          <string>Noto Sans CJK SC</string>
          <string>Noto Sans CJK SC</string>
        </edit>
      </match>

      <!-- Serif (body text, reading) -->
      <match target="pattern">
        <test name="family"><string>serif</string></test>
        <edit name="family" mode="prepend" binding="strong">
          <string>Anthropic Serif Web Text</string>
          <string>Source Han Serif</string>
          <string>Noto Serif CJK SC</string>
        </edit>
      </match>

      <!-- Monospace (terminal, code editor) -->
      <match target="pattern">
        <test name="family"><string>monospace</string></test>
        <edit name="family" mode="prepend" binding="strong">
          <string>Anthropic Mono Variable</string>
          <string>JetBrainsMono Nerd Font</string>
          <string>Sarasa Mono SC</string>
          <string>Noto Sans CJK SC</string>
        </edit>
      </match>
    </fontconfig>
  '';

  # 共享图标主题（GTK 主题 Material-Gnome 在 theme-material.nix，被两变体共同 import）
  home.packages = with pkgs; [
    papirus-icon-theme gnome-themes-extra
  ];

  # GTK4/libadwaita apps need gsettings schemas to read color-scheme
  home.sessionVariables.XDG_DATA_DIRS =
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:\${XDG_DATA_DIRS}";

  # 共享 dconf：图标主题（深浅色由各桌面变体自行决定）。
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      icon-theme = "Papirus";
    };
  };
}
