{ config, lib, pkgs, ... }:

let
  # matugen 配置：一次取色输出多端产物（caelestia scheme.json + Noctalia palette）
  matugenConfig = pkgs.writeText "matugen-wp.toml" ''
    [config]

    [templates.caelestia]
    input_path = '${./matugen/caelestia-scheme.json.tpl}'
    output_path = '${config.home.homeDirectory}/.local/state/caelestia/scheme.json'

    [templates.noctalia]
    input_path = '${./matugen/noctalia-palette.json.tpl}'
    output_path = '${config.home.homeDirectory}/.config/noctalia/palettes/matugen.json'
  '';

  # waypaper post_command 分发脚本：matugen 从壁纸取色 → 多端产物
  # caelestia scheme.json（Colours.qml watchChanges 自动热载）
  # Noctalia matugen.json（palette 文件不被 file_watcher 监听，需 config-reload 触发重读）
  wallpaperThemeScript = pkgs.writeShellScript "wallpaper-theme" ''
    set -euo pipefail
    WALL="$1"
    # matugen 4.x 新版 --prefer=saturation；旧版用 --prefer saturation（空格），fallback 两个
    ${pkgs.matugen}/bin/matugen image "$WALL" -m dark -t scheme-tonal-spot \
      --prefer=saturation -c ${matugenConfig} 2>/dev/null \
      || ${pkgs.matugen}/bin/matugen image "$WALL" -m dark -t scheme-tonal-spot \
      --prefer saturation -c ${matugenConfig}
    # Noctalia palette 文件不自动监听，触发 config-reload 让它重读 matugen.json（切壁纸换色）
    # Noctalia 未运行时忽略（当前 shell 可能是 caelestia/DMS）
    ${pkgs.noctalia}/bin/noctalia msg config-reload 2>/dev/null || true
  '';
in {
  # 壁纸管理 + 动态取色（与 shell 解耦）：waypaper 切壁纸 → matugen 取色 → 各 shell 消费统一产物。
  # Phase 1 只接 caelestia（scheme.json watchChanges 自动热载）；Noctalia palette / Hyprland·niri 边框 / DMS 后续接。
  # swww 在 nixpkgs 已改名 awww（同作者 LGFae 继任，提供 awww/awww-daemon），waypaper 2.8 原生支持 awww 后端。
  home.packages = [ pkgs.waypaper pkgs.awww pkgs.matugen ];

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
  # 用 activation 复制为普通可写文件（rebuild 重新生成声明配置，覆盖 waypaper 运行时保存）。
  # 注意 section 必须是 [Settings]（大写 S）——waypaper config.get("Settings", ...)，小写读不到导致 post_command 为空。
  #
  # 关键：post_command 指向固定路径 wrapper（~/.local/bin/wallpaper-theme），而非 store hash 路径。
  # waypaper 是常驻进程，缓存 post_command 并写回 config.ini；store 路径每次 rebuild 都变，
  # 会被覆盖成旧值。固定路径 + activation 更新内容，路径稳定、内容每次执行读最新。
  home.activation.setupWaypaperTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.local/bin" "$HOME/.config/waypaper"
    cp ${wallpaperThemeScript} "$HOME/.local/bin/wallpaper-theme"
    chmod 755 "$HOME/.local/bin/wallpaper-theme"

    cat > "$HOME/.config/waypaper/config.ini" <<INI
[Settings]
backend = awww
post_command = ${config.home.homeDirectory}/.local/bin/wallpaper-theme \$wallpaper
INI
    chmod 644 "$HOME/.config/waypaper/config.ini"
  '';
}
