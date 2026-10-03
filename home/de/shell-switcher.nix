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

  # 登录 / rebuild 后的 shell 恢复：唯一入口是 `shell-switcher boot`，它读
  # ~/.config/shell-switcher/current 标记拉起上次选的 shell（无标记则用 config.toml 的 default）。
  # 两个触发点都走这里，不直接拉某个 shell：
  #   - 登录：本服务随 graphical-session.target 起。Noctalia 自己的 WantedBy 保持在
  #     graphical-session.target 作为"外壳兜底"，本服务后跑并 stop-all → start 目标，
  #     所以两壳同时起的竞争窗口会被收敛成单 shell（代价是可能有短暂闪烁）。
  #   - rebuild：switch 会重启 graphical-session.target，本服务随之重跑，于是不再需要手工
  #     `shell-switcher set caelestia`；HM 激活器只清理自己命名空间下的文件，
  #     ~/.config/shell-switcher 不在其中，标记得以保留。
  systemd.user.services.shell-switcher-boot = {
    Unit = {
      Description = "Restore last selected desktop shell (shell-switcher boot)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${shellSwitcher}/bin/shell-switcher boot";
      # boot 失败（无标记 / 切换失败）会自行回退 default shell，这里再兜一层重试。
      Restart = "on-failure";
      RestartSec = 5;
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

  # 从启动器直接切换桌面 shell，不必开终端敲命令。
  # 两条 entry 都只是 `shell-switcher set <name>` 的壳：真正的启停编排放切换器，
  # 它内部是 stop-all → await → start，所以从 launcher 点也只会留下一个 shell。
  # 原理：shell-switcher 靠 HYPRLAND_INSTANCE_SIGNATURE / NIRI_SOCKET 做会话防呆，
  # 这两个变量在 systemd 用户环境里（uwsm 写完），launcher 子进程能继承，故无需包装脚本。
  xdg.desktopEntries = {
    "shell-noctalia" = {
      name = "Noctalia Shell";
      genericName = "Desktop Shell";
      comment = "切换到 Noctalia 桌面 shell";
      exec = "${shellSwitcher}/bin/shell-switcher set noctalia";
      # noctalia 的图标在它自己的包内、没进 profile，所以按绝对路径引用。
      icon = "${config.programs.noctalia.package}/share/icons/hicolor/scalable/apps/noctalia.svg";
      categories = [ "Settings" "Utility" ];
      terminal = false;
    };
    "shell-caelestia" = {
      name = "Caelestia Shell";
      genericName = "Desktop Shell";
      comment = "切换到 Caelestia 桌面 shell";
      exec = "${shellSwitcher}/bin/shell-switcher set caelestia";
      icon = "caelestia";
      categories = [ "Settings" "Utility" ];
      terminal = false;
    };
  };

  # Caelestia 的图标只作为 asset 放在 shell 包内，没有装进 hicolor 主题，
  # 所以 launcher 里会显示占位图。这里把它的 logo 装成名为 caelestia 的图标
  # （~/.local/share/icons 也在 XDG_DATA_DIRS 的图标搜索路径里）；
  # Noctalia 的包自带 share/icons/hicolor/.../noctalia.svg，无需处理。
  xdg.dataFile."icons/hicolor/scalable/apps/caelestia.svg".source =
    "${config.programs.caelestia.package}/share/caelestia-shell/assets/logo.svg";

  # fish 补全：NixOS 把 /etc/profiles 固化成 /etc/static 时只保留 bash-completion，
  # 丢 fish/zsh 的 vendor_completions.d。显式装到 ~/.config/fish/completions
  xdg.configFile."fish/completions/shell-switcher.fish".source =
    "${shellSwitcher}/share/fish/vendor_completions.d/shell-switcher.fish";
}
