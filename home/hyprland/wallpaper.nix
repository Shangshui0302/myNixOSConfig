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
  # 壁纸管理 + 动态取色（与 shell 解耦）：waypaper(swww) 切壁纸 → matugen 取色 → 各 shell 消费统一产物。
  # Phase 1 只接 caelestia（scheme.json watchChanges 自动热载）；Noctalia palette / Hyprland·niri 边框 / DMS 后续接。
  home.packages = [ pkgs.waypaper pkgs.swww pkgs.matugen ];

  xdg.configFile."waypaper/config.ini".text = ''
    [settings]
    backend = swww
    post_command = ${wallpaperThemeScript} $wallpaper
  '';
}
