{ config, pkgs, inputs, ... }:

let
  shellSwitcher = inputs.shell-switcher.packages.${pkgs.system}.default;
  desktopShellAction = pkgs.writeShellApplication {
    name = "desktop-shell-action";
    runtimeInputs = [
      shellSwitcher
      config.programs.noctalia.package
      config.programs.caelestia.cli.package
      config.services.clipse.package
      pkgs.foot
      pkgs.hyprland
    ];
    text = ''
      action="''${1:-}"
      shell="$(shell-switcher current 2>/dev/null || true)"
      case "$action:$shell" in
        launcher:caelestia) caelestia shell drawers toggle launcher ;;
        launcher:*) noctalia msg panel-toggle launcher ;;
        control:caelestia) caelestia shell drawers toggle utilities ;;
        control:*) noctalia msg panel-toggle control-center ;;
        settings:caelestia) caelestia shell nexus open ;;
        settings:*) noctalia msg settings-toggle ;;
        clipboard:caelestia) foot --app-id=clipse -e clipse ;;
        clipboard:*) noctalia msg panel-toggle clipboard ;;
        window-switcher:caelestia) hyprctl dispatch cyclenext ;;
        window-switcher:*) noctalia msg window-switcher ;;
        brightness-up:caelestia) caelestia shell brightness set +5% ;;
        brightness-up:*) noctalia msg brightness-up ;;
        brightness-down:caelestia) caelestia shell brightness set 5%- ;;
        brightness-down:*) noctalia msg brightness-down ;;
        *) exit 2 ;;
      esac
    '';
  };
in
{
  # shell-switcher：安装二进制 + 运行时配置（声明可由 switcher 切换的 shell：name → systemd user service）。
  # 各 shell 的 service 由各自模块定义：noctalia（home/de/noctalia.nix，WantedBy 自动起）、
  # caelestia（wantedBy 空，由 switcher 启停）。
  # `shell-switcher set <name>` 切换；默认 Noctalia。
  home.packages = [ shellSwitcher desktopShellAction ];

  # Caelestia 没有 Noctalia 的剪贴板面板，使用 HM 原生 Clipse 保持 Super+C 习惯。
  services.clipse.enable = true;

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
    "${shellSwitcher}/share/fish/vendor_completions.d/shell-switcher.fish";
}
