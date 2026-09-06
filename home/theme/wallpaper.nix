{
  config,
  lib,
  pkgs,
  ...
}:

let
  # waypaper 缓存 post_command；此稳定 wrapper 将壁纸变化委托给主题模式模块。
  wallpaperThemeScript = pkgs.writeShellScript "wallpaper-theme" ''
    mode="$(${pkgs.darkman}/bin/darkman get 2>/dev/null || true)"
    if [ "$mode" != dark ] && [ "$mode" != light ]; then
      mode="$(cat "${config.home.homeDirectory}/.cache/darkman/mode.txt" 2>/dev/null || printf '%s' dark)"
    fi
    exec "${config.home.homeDirectory}/.local/bin/theme-apply" "$mode" "$1"
  '';
in
{
  # 壁纸管理与主题模式解耦：waypaper 只传递新壁纸，theme-apply 决定当前深浅模式。
  # swww 在 nixpkgs 已改名 awww（同作者 LGFae 继任，提供 awww/awww-daemon），waypaper 2.8 原生支持 awww 后端。
  home.packages = [
    pkgs.waypaper
    pkgs.awww
    pkgs.matugen
  ];

  # awww daemon：waypaper 设置壁纸的后端（awww-daemon 前台运行）
  systemd.user.services.awww-daemon = {
    Unit = {
      Description = "awww daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.awww}/bin/awww-daemon";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # waypaper 运行时需写 config.ini（保存当前壁纸等）；Nix symlink 只读会导致
  # "Could not save config file due to permission error" 且 post_command 不触发。
  # 用 activation 复制为普通可写文件；config.ini 只在首次部署时创建，保留 waypaper 运行时状态。
  # 注意 section 必须是 [Settings]（大写 S）——waypaper config.get("Settings", ...)，小写读不到导致 post_command 为空。
  #
  # 关键：post_command 指向固定路径 wrapper（~/.local/bin/wallpaper-theme），而非 store hash 路径。
  # waypaper 是常驻进程，缓存 post_command 并写回 config.ini；store 路径每次 rebuild 都变，
  # 会被覆盖成旧值。固定路径 + activation 更新内容，路径稳定、内容每次执行读最新。
  home.activation.setupWaypaperTheme =
    lib.hm.dag.entryAfter [ "writeBoundary" "setupMatugenGtkTheme" "setupDarkmanMode" ]
      ''
            mkdir -p "$HOME/.local/bin" "$HOME/.config/waypaper" \
              "$HOME/.config/qt5ct/colors" "$HOME/.config/qt6ct/colors" \
              "$HOME/.config/Kvantum/MaterialAdw" "$HOME/.local/share/color-schemes"
            cp ${wallpaperThemeScript} "$HOME/.local/bin/wallpaper-theme"
            chmod 755 "$HOME/.local/bin/wallpaper-theme"

            if [ ! -e "$HOME/.config/waypaper/config.ini" ]; then
              cat > "$HOME/.config/waypaper/config.ini" <<INI
        [Settings]
        backend = awww
        folder = ${config.home.homeDirectory}/Pictures/Wallpapers
        post_command = ${config.home.homeDirectory}/.local/bin/wallpaper-theme \$wallpaper
        wallpaper = ${../../assets/nixos_logo.png}
        INI
              chmod 644 "$HOME/.config/waypaper/config.ini"
            fi

            # 首次部署或迁移到 GTK4 双 palette 时生成完整初始产物；之后保持当前壁纸颜色。
            if [ ! -f "$HOME/.config/qt5ct/colors/matugen.conf" ] \
              || [ ! -f "$HOME/.config/qt6ct/colors/matugen.conf" ] \
              || [ ! -f "$HOME/.config/Kvantum/MaterialAdw/MaterialAdw.kvconfig" ] \
              || [ ! -f "$HOME/.config/Kvantum/MaterialAdw/MaterialAdw.svg" ] \
              || [ ! -f "$HOME/.local/share/color-schemes/MaterialAdwMatugen.colors" ] \
              || ! grep -q 'prefers-color-scheme: dark' "$HOME/.themes/Material-Gnome-Matugen/gtk-4.0/colors.css" 2>/dev/null \
              || [ ! -f "$HOME/.local/share/icons/Papirus-Matugen/index.theme" ]; then
              initial_wallpaper="$(${pkgs.waypaper}/bin/waypaper --list 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[0].wallpaper // empty' 2>/dev/null || true)"
              if [ ! -f "$initial_wallpaper" ]; then
                initial_wallpaper=${../../assets/nixos_logo.png}
              fi
              "$HOME/.local/bin/wallpaper-theme" "$initial_wallpaper"
            fi
      '';
}
