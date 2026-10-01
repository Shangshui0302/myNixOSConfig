{
  config,
  lib,
  ...
}:

# TLP 三档电源管理（取代原 host/base/power.nix 的自写 powerPolicy.*）。
#
# 本机背景：
#   - CPU：AMD Ryzen 7 8845HS，`amd-pstate-epp` 为 active，所以能效偏好走
#     CPU_ENERGY_PERF_POLICY_*（EPP），而不是 intel_pstate 的 CPU_MIN/MAX_PERF_*；
#   - 核显：Radeon 780M，DPM 档位在 /sys/class/drm/card1/device/power_dpm_force_performance_level；
#   - 没有 platform_profile 节点，因此不使用 PLATFORM_PROFILE_ON_* 系列；
#   - TLP 版本锁定在仓库 flake.lock 的 nixpkgs（26.11，rev 7a0f122f5090）里，为 1.10.2；
#     本文件里的 28 个键名已逐个在构建出的 tlp-1.10.2 包内核对存在。
#
# TLP 1.9+ 的档位后缀语义（三档）：
#   _ON_AC  → performance 档（PRF，只有用户手动选择才会进入）
#   _ON_BAT → balanced 档（BAL）
#   _ON_SAV → power-saver 档（SAV）
# 回落规则：某个特性**没有** _ON_SAV 时，TLP 在省电档会回落到 _ON_BAT 的值
#   （TLP 源码 func.d/10-tlp-func-cpu 里写作 `${XXX_ON_SAV:-$XXX_ON_BAT}`）。
#   本模块不依赖这条回落：凡是我们关心的项都显式写全三档。
#
# 与用户级策略的分工：
#   本模块只负责「TLP 会怎么改硬件」这一层（系统层），不决定何时换档。
#   TLP_AUTO_SWITCH=0 关掉 TLP 自己的插拔自动换档，换档权交给用户级策略
#   （手动切换 + 外部策略调用 TLP 的 net.hadess.PowerProfiles D-Bus 接口，
#   由 services.tlp.pd 提供，与 ppd 是同一条接口）。

let
  cfg = config.powerTlp;
in
{
  options.powerTlp = {
    enable = lib.mkEnableOption "TLP 三档电源管理（取代 power-profiles-daemon）" // {
      default = true;
    };

    maxFreq = lib.mkOption {
      type = lib.types.ints.positive;
      default = 5137904;
      description = ''
        本机 CPU 的最高频率（= `cpuinfo_max_freq` / `amd_pstate_max_freq`），单位 kHz。

        为什么必须显式写：TLP 对 `CPU_SCALING_MAX_FREQ_*` 只写「非空且非 0」的值
        （源码 `10-tlp-func-cpu`：`[ -n "$maxfreq" ] && [ "$maxfreq" != "0" ]`）。
        如果均衡/性能档写 0，那么离开省电档时没人把 `scaling_max_freq` 写回去，
        省电档压到 `powerSaverMaxFreq` 的上限会一直粘住（真机实测踩过这个坑）。
        查询方法：`cat /sys/devices/system/cpu/cpufreq/policy0/cpuinfo_max_freq`。
      '';
    };

    powerSaverMaxFreq = lib.mkOption {
      type = lib.types.ints.between 0 6000000;
      default = 2400000;
      description = ''
        省电档 CPU 最高频率，单位 kHz（本机可用范围 419421–5137904）。
        0 = 不限制。这个值只在 power-saver 档生效，是省电档真正「卡频率」的地方。
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # NixOS 的 tlp 模块有断言：services.tlp.pd 与 power-profiles-daemon 不能同时开
    # （两者抢同一条 net.hadess.PowerProfiles D-Bus 接口）。TLP 取代 ppd，所以这里显式关掉。
    services.power-profiles-daemon.enable = false;

    services.tlp = {
      enable = true;
      # 提供 power-profiles-daemon 同款 D-Bus 接口，用户级的三档切换照旧可用。
      pd.enable = true;

      settings = {
        TLP_DISABLE_DEFAULTS = 0; # 保留 TLP 自家省电默认（磁盘/音频/USB 等），我们只覆盖关心的项
        TLP_AUTO_SWITCH = 0; # 关掉 TLP 自己按插拔切档：换档权交给用户级策略
        TLP_PROFILE_DEFAULT = "BAL"; # 启动进均衡
        # 双保险：TLP_PROFILE_AC/BAT 只在 TLP_AUTO_SWITCH=1/2 时才被使用。
        # 这里仍是 BAL，是为了万一将来把 TLP_AUTO_SWITCH 打开，也不会自动进 performance。
        TLP_PROFILE_AC = "BAL";
        TLP_PROFILE_BAT = "BAL";

        # ---- CPU：performance 档只由用户手动选择，任何策略都不进 ----
        # 省电档显式写 _ON_SAV：TLP 只在某项没写 _SAV 时才回落到 _BAT 值，写全三档行为才可读、可控。
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_SCALING_GOVERNOR_ON_SAV = "powersave";
        # amd-pstate-epp active 时，EPP 才是调能效的主开关：
        #   performance = 满血；balance_performance = 均衡偏性能；power = 最省。
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_performance";
        CPU_ENERGY_PERF_POLICY_ON_SAV = "power";
        # Boost：均衡档保留 turbo（日常手感），只有省电档关掉。
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 1;
        CPU_BOOST_ON_SAV = 0;

        # ---- CPU 频率上下限：六项都写 ----
        # 这类参数在 TLP 里没有内建默认值（tlp.conf.in 标 `Default: <none>`），
        # 所以三档 × 上下限共六项全部显式写出，保证任何档位下的频率上限都是我们想要的值。
        # 注意：TLP 只写「非 0」的值 → 均衡/性能档的上限必须写成真实最大值（maxFreq），
        # 否则省电档压下去的上限在切回时不会被恢复（真机实测踩过）。
        # 下限统一 0（不修改，保留内核默认的最低非线性频率 1100980）。
        CPU_SCALING_MIN_FREQ_ON_AC = 0;
        CPU_SCALING_MIN_FREQ_ON_BAT = 0;
        CPU_SCALING_MIN_FREQ_ON_SAV = 0;
        CPU_SCALING_MAX_FREQ_ON_AC = cfg.maxFreq;
        CPU_SCALING_MAX_FREQ_ON_BAT = cfg.maxFreq;
        CPU_SCALING_MAX_FREQ_ON_SAV = cfg.powerSaverMaxFreq; # 省电档真正「卡频率」的地方

        # ---- GPU：核显 DPM 档位跟随电源档 ----
        # amdgpu 接受 auto / low / high：auto = 动态调频（空闲降频、负载升频）；
        # low 把核显钉在最低频。performance 也用 auto，不用 high——high 会把核显钉死最高频，
        # 对笔记本核显是纯多耗电。
        RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
        RADEON_DPM_PERF_LEVEL_ON_BAT = "auto";
        RADEON_DPM_PERF_LEVEL_ON_SAV = "low";

        # ---- 面板自刷新省电（ABM）----
        # TLP 默认是 AC=0 / BAT=1 / SAV=3。均衡档按要求不做面板省电（保持 0），
        # 只在省电档开 1 级，避免在插电/均衡时改变屏幕观感。
        # 注：本机核显没有暴露 ABM 节点（/sys/class/drm/*/device/amdgpu/panel_power_savings
        # 不存在，TLP 会静默跳过），所以这几项目前是空操作；保留是为了换机型/内核后能生效。
        AMDGPU_ABM_LEVEL_ON_AC = 0;
        AMDGPU_ABM_LEVEL_ON_BAT = 0; # 均衡档不做面板省电（用户要求）
        AMDGPU_ABM_LEVEL_ON_SAV = 1;

        # ---- WiFi 省电：钉死关闭 ----
        # TLP 默认在电池上开 wifi 省电（WIFI_PWR_ON_BAT=on），这是 Intel AX200 常见的
        # 卡顿/掉线来源；钉死 off = 保持用户现状，不随电源档变化。
        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "off";
      };
    };
  };
}
