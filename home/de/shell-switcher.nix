{ pkgs, inputs, ... }:
{
  # shell-switcher：安装二进制 + 运行时配置（声明可由 switcher 切换的 shell：name → systemd user service）。
  # 各 shell 的 service 由各自模块定义：noctalia（home/de/noctalia.nix，WantedBy 自动起）、
  # caelestia（wantedBy 空，由 switcher 启停）。
  # `shell-switcher set <name>` 切换；默认 Noctalia。
  home.packages = [
    inputs.shell-switcher.packages.${pkgs.system}.default
  ];

  xdg.configFile."shell-switcher/config.toml".text = ''
    # 默认 shell：boot 无标记 / 切换失败回退时使用
    default = "noctalia"

    [[shell]]
    name = "noctalia"
    service = "noctalia.service"

    [[shell]]
    name = "caelestia"
    service = "caelestia.service"
  '';

  # fish 补全：NixOS 把 /etc/profiles 固化成 /etc/static 时只保留 bash-completion，
  # 丢 fish/zsh 的 vendor_completions.d。显式装到 ~/.config/fish/completions
  # （fish_complete_path 第一项，与 howdy/hyprctl/hyprland 补全同模式）。
  xdg.configFile."fish/completions/shell-switcher.fish".source =
    "${inputs.shell-switcher.packages.${pkgs.system}.default}/share/fish/vendor_completions.d/shell-switcher.fish";
}
