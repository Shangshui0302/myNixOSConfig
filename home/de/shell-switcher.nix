{ config, lib, pkgs, inputs, ... }:

let
  shellSwitcher = inputs.shell-switcher.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # 剪贴板历史：caelestia 的 `caelestia clipboard` 就是 cliphist + fuzzel 的封装
  # （cli 自带这两个依赖，此处补的是系统 PATH 与常驻 store watcher）。
  clipboardStore = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${lib.getExe pkgs.cliphist} store";
  desktopShellAction = pkgs.writeShellApplication {
    name = "desktop-shell-action";
    runtimeInputs = [
      shellSwitcher
      config.programs.noctalia.package
      config.programs.caelestia.cli.package
      pkgs.hyprland
    ];
    text = ''
      action="''${1:-}"
      shell="$(shell-switcher current 2>/dev/null || true)"
      case "$action:$shell" in
        launcher:caelestia) caelestia shell drawers toggle launcher ;;
        launcher:*) noctalia msg panel-toggle launcher ;;
        dashboard:caelestia) caelestia shell drawers toggle dashboard ;;
        sidebar:caelestia) caelestia shell drawers toggle sidebar ;;
        # 面板总开关：dashboard + osd 一起切（等价于 shell 的 caelestia:showall 减去 launcher）。
        # 不含 launcher：它一打开就抢键盘焦点，会把同一批里后续的 toggle 命令打断
        # （实测 showall 首按只开成 launcher+dashboard，osd 丢失）。launcher 由 SPACE 键单独负责，
        # utilities 由 control 键负责，这里都不碰。
        showall:caelestia)
          for drawer in dashboard osd; do
            caelestia shell drawers toggle "$drawer"
          done
          ;;
        control:caelestia) caelestia shell drawers toggle utilities ;;
        control:*) noctalia msg panel-toggle control-center ;;
        settings:caelestia) caelestia shell nexus open ;;
        settings:*) noctalia msg settings-toggle ;;
        # session 菜单只有 caelestia 有（Noctalia 侧无对应面板），不设通配分支。
        session:caelestia) caelestia shell drawers toggle session ;;
        # caelestia 没有剪贴板面板，走它自带的 cliphist+fuzzel 入口。
        clipboard:caelestia) caelestia clipboard ;;
        clipboard:*) noctalia msg panel-toggle clipboard ;;
        clipboard-delete:caelestia) caelestia clipboard -d ;;
        clipboard-delete:*) noctalia msg clipboard-clear ;;
        media-playpause:caelestia) caelestia shell mpris playPause ;;
        media-playpause:*) noctalia msg media toggle ;;
        media-next:caelestia) caelestia shell mpris next ;;
        media-next:*) noctalia msg media next ;;
        media-prev:caelestia) caelestia shell mpris previous ;;
        media-prev:*) noctalia msg media previous ;;
        media-stop:caelestia) caelestia shell mpris stop ;;
        media-stop:*) noctalia msg media stop ;;
        lock:caelestia) caelestia shell lock lock ;;
        lock:*) noctalia msg session lock ;;
        window-switcher:caelestia) hyprctl dispatch cyclenext ;;
        window-switcher:*) noctalia msg window-switcher ;;
        brightness-up:caelestia) caelestia shell brightness set +5% ;;
        brightness-up:*) noctalia msg brightness-up ;;
        brightness-down:caelestia) caelestia shell brightness set 5%- ;;
        brightness-down:*) noctalia msg brightness-down ;;
        screenshot:caelestia) caelestia screenshot ;;
        screenshot:*) noctalia msg screenshot-region ;;
        record:caelestia) caelestia record -s ;;
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
  #
  # 剪贴板历史：改用 caelestia 自带路径（cliphist + fuzzel），替掉原来的 Clipse。
  # 两者都要 cliphist 存历史，所以补上系统 PATH 与常驻 watcher；
  # 选择器 UI 由 caelestia CLI 用 fuzzel 提供（launcher 动作 "Clipboard" 与 Super+C 都走它）。
  home.packages = [ shellSwitcher desktopShellAction pkgs.cliphist pkgs.fuzzel ];

  systemd.user.services.cliphist = {
    Unit = {
      Description = "Clipboard history watcher (cliphist)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = clipboardStore;
      Restart = "always";
      RestartSec = 2;
      # wl-paste --watch 被 SIGTERM 停掉时不一定立刻退出，给它留足停止窗口。
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

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
  xdg.configFile."fish/completions/shell-switcher.fish".source =
    "${shellSwitcher}/share/fish/vendor_completions.d/shell-switcher.fish";
}
