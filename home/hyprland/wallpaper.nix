{ config, lib, pkgs, ... }:

let
  # matugen 配置：定义 caelestia scheme.json 模板输出（唯一消费端，Phase 1）
  matugenConfig = pkgs.writeText "matugen-wp.toml" ''
    [config]

    [templates.caelestia]
    input_path = '${./matugen/caelestia-scheme.json.tpl}'
    output_path = '${config.home.homeDirectory}/.local/state/caelestia/scheme.json'
  '';

  # waypaper post_command 分发脚本：matugen 从壁纸取色 → caelestia scheme.json
  # caelestia 的 Colours.qml watchChanges 监听该文件，保存即热重载（无需重启 shell）
  wallpaperThemeScript = pkgs.writeShellScript "wallpaper-theme" ''
    set -euo pipefail
    WALL="$1"
    # matugen 4.x 新版 --prefer=saturation；旧版用 --prefer saturation（空格），fallback 两个
    ${pkgs.matugen}/bin/matugen image "$WALL" -m dark -t scheme-tonal-spot \
      --prefer=saturation -c ${matugenConfig} 2>/dev/null \
      || ${pkgs.matugen}/bin/matugen image "$WALL" -m dark -t scheme-tonal-spot \
      --prefer saturation -c ${matugenConfig}
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
  home.activation.setupWaypaperConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/waypaper"
    cat > "$HOME/.config/waypaper/config.ini" <<'INI'
[Settings]
backend = awww
post_command = ${wallpaperThemeScript} $wallpaper
INI
    chmod 644 "$HOME/.config/waypaper/config.ini"
  '';
}
