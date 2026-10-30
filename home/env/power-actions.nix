{
  config,
  lib,
  pkgs,
  ...
}:

# 电源档位的「用户层动作 + 电量阈值策略」（Home Manager 侧）。
#
# 事实源是 TLP：系统层跑 tlp-pd，它在 D-Bus 上同时提供 net.hadess.PowerProfiles 与
# org.freedesktop.UPower.PowerProfiles；用户侧的命令行入口是 tlpctl（tlp-pd 输出里的
# D-Bus 客户端，普通用户可用，不需要 root）。三档 performance / balanced / power-saver，
# balanced 是默认档。tlp-pd 自己负责 CPU EPP / GPU DPM 这些只有 root 能做的事。
#
# 本模块只做两件事：
#
#   1) 电量阈值策略（policy）：只在 balanced ↔ power-saver 之间自动切，
#      **永不自动进 performance**（performance 只能由用户手动 mode performance 进入）。
#        用电池且电量 < powerSaverBelow → power-saver
#        插电且电量 ≥ balancedAbove   → balanced
#        其它情况不动 —— 40/60 之间就是 20% 的滞回窗口，避免贴着阈值反复横跳
#      策略是**边沿触发**的：只在 band（档位区域 saver/balanced/neutral）发生变化时才动手，
#      band 记在 $XDG_RUNTIME_DIR/power-actions/band。于是同一个 band 内用户手动选的档位
#      （尤其是手动进 performance）不会被定时器顶掉；只有真的跨到另一个 band 才会被策略接管。
#      刻意不使用 TLP 的 profile hold（用户明确不要）。
#      探测不到 type=Battery 的机器（台式机）直接不切档。
#
#   2) 会话层动作：只有 power-saver 档才关 Hyprland 特效、暂停指定用户单元、必要时切深色；
#      离开 power-saver（进 balanced 或 performance）恢复原值并起回用户单元。
#      darkman 只在进入时切 dark，离开时**不动**（交给它自己的日出/日落调度）。
#
# 为什么必须有用户层：darkman/hyprctl/`systemctl --user` 都需要会话环境（会话总线、
# XDG_RUNTIME_DIR、合成器 socket），root 的 TLP 侧做不了。
#
# 触发：user timer 每 pollSeconds 跑一次 `run`，一次做两件事 —— 先跑电量策略
# （可能要 tlpctl set），再对齐会话层。会话层里只有 Hyprland 特效值每轮都做
# 「漂移纠正」（主题重载会把值改回去）；darkman 只在本轮真的要进/离省电档时才调
# （每轮调 `darkman set` 会连带触发 theme-apply：Matugen 重渲染 + 重启 fcitx5）。
# 用户单元在档位变化时动，另外在档位未变但 state 里还有「上次没恢复成功」的记录时
# 也会重试恢复（见 session_step）；`revert` 之后到下次档位变化之前，会话层整体暂停。

let
  cfg = config.powerActions;

  pollSeconds = toString cfg.pollSeconds;
  units = lib.concatStringsSep " " cfg.pauseUserUnits;

  # 注入脚本的「Hyprland option → 省电档目标字面量」行表（一行一个 "option 字面量"）。
  # option 名与 bool/int/float 字面量都不含空格，所以按空格切分是安全的。
  effectValues = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (kw: value: "${kw} ${value}") cfg.hyprlandEffects.values
  );

  actionsScript = pkgs.writeShellApplication {
    name = "power-actions";
    runtimeInputs =
      with pkgs;
      [
        systemd # systemctl --user
        coreutils
        util-linux # flock：串行化 run/mode/apply/revert 与 status
        tlp-pd # tlpctl：tlp-pd 的 D-Bus 客户端，普通用户即可读写档位
      ]
      ++ lib.optional cfg.hyprlandEffects.enable pkgs.hyprland
      ++ lib.optional cfg.darkMode pkgs.darkman;
    text = builtins.replaceStrings
      [
        "@power_saver_profile@"
        "@dark_mode@"
        "@effects_enabled@"
        "@policy_enabled@"
        "@power_saver_below@"
        "@balanced_above@"
        "@pause_units@"
        "@effects_values@"
        "@power_supply_dir@"
      ]
      [
        cfg.powerSaverProfile
        (lib.boolToString cfg.darkMode)
        (lib.boolToString cfg.hyprlandEffects.enable)
        (lib.boolToString cfg.policy.enable)
        (toString cfg.policy.powerSaverBelow)
        (toString cfg.policy.balancedAbove)
        units
        effectValues
        "/sys/class/power_supply"
      ]
      (builtins.readFile ./scripts/power-actions.sh);
  };

  # writeShellApplication 的产物在 $out/bin/power-actions；这里落成**单文件** store 路径：
  # home.file.source 就是一个 store path（HM 建 ~/.local/bin 链接最省事），
  # 且 `nix build ...home.file."...".source` 能直接给出可执行的脚本路径
  # （直接给 $out/bin/... 这种「derivation 输出的子路径」字符串，nix build 会报
  #  "not the right placeholder for this derivation output"）。
  actionsExe = pkgs.runCommandLocal "power-actions" { } ''
    install -m755 ${lib.getExe actionsScript} $out
  '';
in
{
  options.powerActions = {
    enable = lib.mkEnableOption "按 TLP 档位调整会话内设置并执行电量阈值策略，提供 power-actions 手动入口" // {
      default = true;
    };

    powerSaverProfile = lib.mkOption {
      type = lib.types.str;
      default = "power-saver";
      description = "触发「省电动作」的 TLP 档位名（须是 tlp-pd 支持的档位）。";
    };

    pollSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 30;
      description = "轮询 TLP 档位与电量的间隔（秒）。只决定自动/手动切换后会话层跟上的延迟。";
    };

    darkMode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        进入省电档时调 darkman 切深色（已经是 dark 就不动）；**离开省电不做任何事**，
        交给 darkman 自己的日出/日落调度。手动切回用 Super+Shift+D。
      '';
    };

    hyprlandEffects = {
      enable = lib.mkEnableOption "进入省电档时改写 Hyprland option（离开时按原值恢复）" // {
        default = true;
      };

      values = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          # 省电档不「关模糊」，而是把模糊调便宜：成本只看 passes（源码里降/升采样各跑
          # passes 次 → 共 2×passes 次 draw），与 size 无关；强度是 size × 2^passes。
          # 本机原值 15/4（半径 240、8 次 draw）→ 省电档 5/2（半径 20、4 次 draw，开销减半）。
          # 之所以不关：foot（alpha=0.8）、noctalia bar/panel、fcitx5 候选窗都是应用自己画的
          # 半透明，模糊一关它们就直接透出桌面（看起来像"变透明"），关模糊反而更难看。
          "decoration:blur:size" = "5";
          "decoration:blur:passes" = "2";
          "decoration:shadow:enabled" = "false";
          "animations:enabled" = "false";
          "decoration:active_opacity" = "1.0";
          "decoration:inactive_opacity" = "1.0";
        };
        description = ''
          省电档要写入的 Hyprland option：键 = `hyprctl -j getoption` 接受的 option 名
          （`a:b` 分段），值 = 要写入的字面量。
          进入省电档时会先把**当前值连同类型**（bool:/int:/float:）记进 state，离开省电档
          时按原值写回，而不是无脑设回 true —— 本机原值是 decoration:active_opacity = 0.88、
          decoration:inactive_opacity = 0.82、decoration:blur:size = 15、passes = 4，
          所以这里的值只是省电档下的目标值，离开时会自动还原成上面这些原值。
          bool/int/float 三种类型都支持（float 型 JSON 里没有 int 字段，别只认 int）。
          niri 没有运行时 option 接口，那部分在 niri 会话里自然是空操作。
        '';
      };
    };

    pauseUserUnits = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "onedrive" ];
      description = "进入省电档时暂停、离开省电档时恢复的用户 systemd 单元（只在它本来 active 时才停）。";
    };

    policy = {
      enable = lib.mkEnableOption "按电量阈值在 balanced ↔ power-saver 之间自动切档" // {
        default = true;
      };

      powerSaverBelow = lib.mkOption {
        type = lib.types.ints.between 0 100;
        default = 40;
        description = "用电池且电量低于该百分比时切到 powerSaverProfile。";
      };

      balancedAbove = lib.mkOption {
        type = lib.types.ints.between 0 100;
        default = 60;
        description = ''
          插电且电量不低于该百分比时切回 balanced。
          与 powerSaverBelow 之间的差值就是滞回窗口（默认 40/60 = 20%），
          窗口内不切档，避免贴着阈值反复横跳。
          **策略永远不会自动进 performance**，那一档只能由用户手动 `power-actions mode performance` 进入；
          并且只有 band（saver/balanced/neutral）发生变化时才会动手，所以同一个 band 内
          用户手动选的档位不会被定时器顶掉。
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # 统一手动入口，和 theme-apply 一样放 ~/.local/bin（已在 PATH 上）
    home.file.".local/bin/power-actions" = {
      source = actionsExe;
      executable = true;
    };

    systemd.user.services.power-profile-actions = {
      Unit = {
        Description = "TLP 档位：电量阈值策略 + 会话层动作（darkman/Hyprland/用户单元）";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${actionsExe} run";
      };
    };

    systemd.user.timers.power-profile-actions = {
      Unit = {
        Description = "轮询 TLP 档位与电量（每 ${pollSeconds}s）";
      };
      Timer = {
        OnBootSec = "30s";
        OnUnitActiveSec = "${pollSeconds}s";
        AccuracySec = "5s";
      };
      # 挂在图形会话上：带 linger 的用户管理器在无会话时不会乱跑
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
