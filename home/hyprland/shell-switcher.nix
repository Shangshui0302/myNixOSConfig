{ ... }:
{
  # shell-switcher 运行时配置：声明可由 switcher 切换的 shell（name → systemd user service）。
  # 各 shell 的 service 由各自模块定义：noctalia（home/hyprland/noctalia.nix，WantedBy 自动起）、
  # dms（host/hyprland/dms-shell.nix，wantedBy 空，由 switcher 启停）。
  # `shell-switcher set <name>` 切换；默认 Noctalia。
  xdg.configFile."shell-switcher/config.toml".text = ''
    [[shell]]
    name = "noctalia"
    service = "noctalia.service"

    [[shell]]
    name = "dms"
    service = "dms.service"

    [[shell]]
    name = "caelestia"
    service = "caelestia.service"
  '';
}
