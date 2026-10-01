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
    runtimeInputs = with pkgs; [
      systemd # systemctl --user
      coreutils
      hyprland # hyprctl（锁定 nixpkgs 的 0.56.2，与运行中的合成器同版本）
      darkman
      tlp-pd # tlpctl：tlp-pd 的 D-Bus 客户端，普通用户即可读写档位
    ];
    text = ''
      # ↓↓↓ 由 home/env/power-actions.nix 注入，改配置请改 nix ↓↓↓
      power_saver_profile="${cfg.powerSaverProfile}"
      balanced_profile="balanced"
      dark_mode=${lib.boolToString cfg.darkMode}
      effects_enabled=${lib.boolToString cfg.hyprlandEffects.enable}
      policy_enabled=${lib.boolToString cfg.policy.enable}
      power_saver_below=${toString cfg.policy.powerSaverBelow}
      balanced_above=${toString cfg.policy.balancedAbove}
      pause_units="${units}"
      effects_values="${effectValues}"

      runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      state_dir="$runtime_dir/power-actions"
      state_file="$state_dir/state"
      band_file="$state_dir/band"
      mkdir -p "$state_dir"

      profiles="performance balanced power-saver"

      log() { printf '%s\n' "$*"; }
      warn() { printf '%s\n' "$*" >&2; }
      die() { printf '%s\n' "$*" >&2; exit 1; }

      usage() {
        cat <<'EOF'
      用法: power-actions [子命令] [参数]

        status            打印 TLP 当前档位、电量策略 band、AC/电量、Hyprland 各 option
                          当前值、darkman、被暂停的用户单元，以及 state 文件路径与内容
        mode [档位]       不带参数=看当前档位；带参数=tlpctl set 设档并立刻对齐会话层
                          （档位: performance | balanced | power-saver）
        apply             按当前档位强制对齐一次（幂等）
        revert            强制恢复成「非省电」状态（特效/用户单元；darkman 不动）
        run               定时器入口：先跑电量策略（可能 tlpctl set），再对齐会话层
        help              本帮助
      EOF
      }

      # ── TLP 档位（tlpctl）───────────────────────────────────────────
      get_profile() { # 打印当前档位；tlpctl 不可用时输出空串
        local raw
        # stderr 不重定向：tlp-pd 没在跑时错误信息要能进 journal
        raw="$(tlpctl get || true)"
        printf '%s' "$raw" | tr -d '[:space:]'
      }

      set_profile() { # set_profile <档位>
        tlpctl set "$1"
      }

      # ── 电池 / AC（sysfs，只读）─────────────────────────────────────
      battery_capacity() { # 打印最低的电池容量百分比；没有电池时返回 1
        local d t c best=""
        for d in /sys/class/power_supply/*/; do
          [ -r "$d/type" ] || continue
          t="$(cat "$d/type" 2>/dev/null || true)"
          [ "$t" = "Battery" ] || continue
          c="$(cat "$d/capacity" 2>/dev/null || true)"
          case "$c" in
            ""|*[!0-9]*) continue ;;
          esac
          if [ -z "$best" ] || [ "$c" -lt "$best" ]; then
            best="$c"
          fi
        done
        [ -n "$best" ] || return 1
        printf '%s' "$best"
      }

      ac_online() { # 插电返回 0，用电池返回 1
        local d mains_seen=false
        # 有独立 AC 适配器节点（Mains）时以它为准：**任一** Mains online=1 即算插电。
        # 双适配器机器上可能出现 AC0 offline + AC1 online，只看第一个会误判成「用电池」。
        for d in /sys/class/power_supply/*/; do
          [ -r "$d/type" ] || continue
          [ "$(cat "$d/type" 2>/dev/null || true)" = "Mains" ] || continue
          mains_seen=true
          [ "$(cat "$d/online" 2>/dev/null || true)" = "1" ] && return 0
        done
        # 有 Mains 节点但都没有 online → 用电池（不退回看电池 status，避免 USB-C 端口误判）
        if [ "$mains_seen" = "true" ]; then
          return 1
        fi
        # 没有 Mains 节点（USB-C PD 供电的机器）时退回看电池 status。
        # 刻意不看 type=USB 的 ucsi-source-psy 端口：那是本机**对外供电**的端口，
        # 插个手机上去也会 online=1，不能当成「插了电源」。
        for d in /sys/class/power_supply/*/; do
          [ -r "$d/type" ] || continue
          [ "$(cat "$d/type" 2>/dev/null || true)" = "Battery" ] || continue
          case "$(cat "$d/status" 2>/dev/null || true)" in
            Charging|Full|"Not charging") return 0 ;;
          esac
        done
        return 1
      }

      current_band() { # 打印当前 band（saver/balanced/neutral）；没有电池时返回 1
        local cap
        cap="$(battery_capacity)" || return 1
        if ac_online; then
          if [ "$cap" -ge "$balanced_above" ]; then
            printf 'balanced'
            return 0
          fi
        else
          if [ "$cap" -lt "$power_saver_below" ]; then
            printf 'saver'
            return 0
          fi
        fi
        printf 'neutral'
      }

      # ── 会话内目标 ──────────────────────────────────────────────────
      hypr_sig() {
        local d
        for d in "$runtime_dir"/hypr/*/; do
          [ -e "$d/.socket.sock" ] || continue
          basename "$d"
          return 0
        done
        return 1
      }

      hypr_get() { # hypr_get <签名> <option> → bool:true / int:15 / float:0.880000；空 = 读不到
        local json value
        json="$(HYPRLAND_INSTANCE_SIGNATURE="$1" hyprctl -j getoption "$2" 2>/dev/null || true)"
        # Hyprland 0.56 的 JSON 按 option 类型给不同字段：
        #   bool  → {"option":"...", "bool": true, "set": true}
        #   int   → {"option":"...", "int": 15, "set": true}
        #   float → {"option":"...", "float": 0.880000, "set": true}   ← **没有 int 字段**
        # 只认 "int" 会同时漏掉 blur/shadow/animations（bool）和 opacity（float），这两个坑都踩过。
        case "$json" in
          *'"bool"'*)
            value="$(printf '%s' "$json" | sed -n 's/.*"bool": *\(true\|false\).*/\1/p')"
            [ -n "$value" ] || return 0
            printf 'bool:%s' "$value"
            ;;
          *'"float"'*)
            value="$(printf '%s' "$json" | sed -n 's/.*"float": *\(-\{0,1\}[0-9][0-9.]*\).*/\1/p')"
            [ -n "$value" ] || return 0
            printf 'float:%s' "$value"
            ;;
          *'"int"'*)
            value="$(printf '%s' "$json" | sed -n 's/.*"int": *\(-\{0,1\}[0-9]\{1,\}\).*/\1/p')"
            [ -n "$value" ] || return 0
            printf 'int:%s' "$value"
            ;;
        esac
      }

      # Hyprland 0.56 用 Lua 配置解析器：旧的 `hyprctl keyword` 在 non-legacy parser 下
      # 完全不生效，却只把错误打到 stdout 且**退出码仍是 0**。所以运行时改配置只能走
      # `hyprctl eval 'hl.config({...})'`，且成功判据是「输出为 ok」而不是退出码。
      # 这里刻意不吞输出：失败原因必须能进 journal。
      hypr_eval() { # hypr_eval <签名> <lua 表达式>
        local out
        out="$(HYPRLAND_INSTANCE_SIGNATURE="$1" hyprctl eval "$2" 2>&1 || true)"
        case "$out" in
          ok*) return 0 ;;
          *)
            warn "hyprctl eval 失败: $out"
            return 1
            ;;
        esac
      }

      hypr_set() { # hypr_set <签名> <option a:b:c> <字面量>
        # a:b:c → ["a"] = { ["b"] = { ["c"] = <值> } }（方括号键，段里含 . 也安全）
        local sig="$1" kw="$2" value="$3" path closes
        path="$(printf '%s' "$kw" | sed -e 's/^/["/' -e 's/$/"]/' -e 's/:/"] = { ["/g')"
        closes="$(printf '%s' "$kw" | tr -cd ':' | sed 's/:/ }/g')"
        hypr_eval "$sig" "hl.config({ $path = $value $closes })"
      }

      unit_active() { systemctl --user is-active --quiet "$1" 2>/dev/null; }

      # ── state（键值行；放 XDG_RUNTIME_DIR，重启即清）────────────────
      state_get() {
        [ -f "$state_file" ] || return 1
        grep -m1 "^$1=" "$state_file" 2>/dev/null | cut -d= -f2- || return 1
      }

      state_set() { # 覆盖式写单个键，保留其它键
        local key="$1" val="$2" tmp="$state_file.tmp"
        {
          if [ -f "$state_file" ]; then
            grep -v "^$key=" "$state_file" || true
          fi
          printf '%s=%s\n' "$key" "$val"
        } > "$tmp"
        mv -f "$tmp" "$state_file"
      }

      state_del() { # 删掉单个键，保留其它键（恢复成功的条目才删，失败的要留着重试）
        local key="$1" tmp="$state_file.tmp"
        [ -f "$state_file" ] || return 0
        grep -v "^$key=" "$state_file" > "$tmp" || true
        mv -f "$tmp" "$state_file"
      }

      state_has_actions() { # state 里是否还有 kw:/unit: 动作记录
        [ -f "$state_file" ] || return 1
        grep -qE '^(kw|unit):' "$state_file"
      }

      record_band() { # band 是「边沿触发」的游标，只有真的切成功（或落到 neutral）才推进
        printf '%s\n' "$1" > "$band_file"
      }

      # ── 动作 ────────────────────────────────────────────────────────
      norm_literal() { # 把字面量归一化成可比较的串：bool 原样，数值用 printf %g 去尾随 0
        local v="$1"
        case "$v" in
          true|false)
            printf '%s' "$v"
            return 0
            ;;
        esac
        case "$v" in
          -[0-9]*|[0-9]*) ;;
          *)
            printf '%s' "$v"
            return 0
            ;;
        esac
        case "$v" in
          *[!0-9.]*)
            printf '%s' "$v"
            return 0
            ;;
        esac
        case "$v" in
          *.*.*)
            printf '%s' "$v"
            return 0
            ;;
        esac
        printf '%g' "$v"
        return 0
      }

      effects_sync() { # 省电档下把特效对齐到期望值；原值只在「首次真的改动」后保存一次
        local sig kw want cur saved
        [ "$effects_enabled" = "true" ] || return 0
        sig="$(hypr_sig)" || return 0
        while read -r kw want; do
          [ -n "$kw" ] || continue
          if [ -z "$want" ]; then
            warn "hyprland: $kw 的目标字面量为空，跳过"
            continue
          fi
          cur="$(hypr_get "$sig" "$kw")"
          saved="$(state_get "kw:$kw" || true)"

          if [ -n "$saved" ]; then
            # 已经接管过这个 option：只有值被改回去（主题重载等）才重写，原值保持不变
            if [ "$(norm_literal "''${cur#*:}")" = "$(norm_literal "$want")" ]; then
              continue
            fi
            if hypr_set "$sig" "$kw" "$want"; then
              log "hyprland: $kw 漂移纠正 -> $want（原值 ''${saved#*:} 保持不变）"
            else
              warn "hyprland: $kw 漂移纠正失败（当前 ''${cur:-读不到}）"
            fi
            continue
          fi

          # 第一次接管：值本来就是期望值就不动、也不记原值
          # （记了会在离开省电档时把期望值当成原值写回去）
          case "$cur" in
            bool:*|int:*|float:*) ;;
            *)
              warn "hyprland: 读不到 $kw 的类型（''${cur:-空}），跳过"
              continue
              ;;
          esac
          if [ "$(norm_literal "''${cur#*:}")" = "$(norm_literal "$want")" ]; then
            continue
          fi
          if hypr_set "$sig" "$kw" "$want"; then
            state_set "kw:$kw" "$cur"
            log "hyprland: $kw -> $want（原值 ''${cur#*:}）"
          else
            warn "hyprland: $kw 写入失败，不记录原值"
          fi
        done <<< "$effects_values"
      }

      session_enter() { # 进入省电档：darkman + 特效 + 用户单元
        local cur u
        if [ "$dark_mode" = "true" ]; then
          cur="$(darkman get || true)"
          if [ "$cur" != "dark" ]; then
            if darkman set dark >/dev/null; then
              log "darkman: ''${cur:-未知} -> dark"
            else
              warn "darkman: set dark 失败（darkman 没在跑？）"
            fi
          fi
        fi

        effects_sync

        for u in $pause_units; do
          [ -n "$u" ] || continue
          state_get "unit:$u" >/dev/null 2>&1 && continue
          if unit_active "$u"; then
            if systemctl --user stop "$u"; then
              state_set "unit:$u" stopped
              log "已暂停用户单元 $u"
            else
              warn "用户单元 $u 暂停失败"
            fi
          fi
        done
      }

      session_leave() { # 离开省电档：按原值恢复特效与用户单元（darkman 按设计不动）
        # 只有**成功恢复**的条目才从 state 里删掉；失败的保留，下一轮 run 继续重试。
        # 否则一次 hyprctl/systemctl 抖动就会把原值记录抹掉，原值再也回不来。
        local sig kw key val orig u lines
        [ -f "$state_file" ] || return 0
        lines="$(cat "$state_file")"

        if [ "$effects_enabled" = "true" ] && sig="$(hypr_sig)"; then
          while IFS= read -r line; do
            case "$line" in kw:*) ;; *) continue ;; esac
            key="''${line%%=*}"
            val="''${line#*=}"
            kw="''${key#kw:}"
            orig="''${val#*:}" # 去掉 bool:/int:/float: 类型前缀，写回原始字面量
            if hypr_set "$sig" "$kw" "$orig"; then
              state_del "$key"
              log "hyprland: $kw -> $orig（恢复原值）"
            else
              warn "hyprland: $kw 恢复失败（想写回 $orig），保留原值记录，下轮重试"
            fi
          done <<< "$lines"
        fi

        while IFS= read -r line; do
          case "$line" in unit:*) ;; *) continue ;; esac
          key="''${line%%=*}"
          val="''${line#*=}"
          u="''${key#unit:}"
          [ "$val" = "stopped" ] || continue
          if systemctl --user start "$u"; then
            state_del "$key"
            log "已恢复用户单元 $u"
          else
            warn "用户单元 $u 启动失败，保留记录，下轮重试"
          fi
        done <<< "$lines"
      }

      session_dispatch() { # session_dispatch <档位>：让会话层与该档位一致
        # 显式对齐（档位变化 / mode / apply）一律解除 revert 留下的「暂停会话层」标记
        state_del session
        if [ "$1" = "$power_saver_profile" ]; then
          session_enter
          state_set profile "$1"
        else
          session_leave
          state_set profile "$1"
        fi
      }

      # ── 定时器入口的两个步骤 ────────────────────────────────────────
      policy_step() { # 电量阈值策略：只在 band 变化时切档，且只在 balanced ↔ power-saver 之间切
        local cap plugged=false band prev
        [ "$policy_enabled" = "true" ] || return 0

        if ! cap="$(battery_capacity)"; then
          log "电量策略: 探测不到电池（type=Battery），不切档"
          return 0
        fi
        if ac_online; then plugged=true; fi

        if [ "$plugged" = "true" ]; then
          if [ "$cap" -ge "$balanced_above" ]; then
            band=balanced
          else
            band=neutral
          fi
        else
          if [ "$cap" -lt "$power_saver_below" ]; then
            band=saver
          else
            band=neutral
          fi
        fi

        prev="$(cat "$band_file" 2>/dev/null || true)"
        if [ "$band" = "$prev" ]; then
          return 0
        fi

        case "$band" in
          saver)
            if set_profile "$power_saver_profile"; then
              record_band "$band"
              log "电量策略: 电池 $cap% < $power_saver_below%，档位 -> $power_saver_profile"
            else
              warn "电量策略: tlpctl set $power_saver_profile 失败（tlp-pd 没在跑？），下轮重试"
            fi
            ;;
          balanced)
            if set_profile "$balanced_profile"; then
              record_band "$band"
              log "电量策略: 插电 $cap% >= $balanced_above%，档位 -> $balanced_profile"
            else
              warn "电量策略: tlpctl set $balanced_profile 失败（tlp-pd 没在跑？），下轮重试"
            fi
            ;;
          *)
            record_band "$band"
            log "电量策略: band -> neutral（$cap%，滞回窗口内），保持当前档位"
            ;;
        esac
      }

      session_step() { # 读当前档位 → 对齐 darkman/特效/用户单元
        local profile prev
        profile="$(get_profile)"
        if [ -z "$profile" ]; then
          warn "读不到 TLP 档位（tlp-pd 没在跑？），跳过会话层对齐"
          return 0
        fi
        prev="$(state_get profile || true)"
        if [ "$profile" != "$prev" ]; then
          session_dispatch "$profile"
          return 0
        fi
        # 档位没变：darkman 与用户单元按设计不动（避免 theme-apply 抖动）。
        if [ "$profile" = "$power_saver_profile" ]; then
          if [ "$(state_get session || true)" = "paused" ]; then
            # revert 之后是「暂停会话层」：不施加、也不做漂移纠正；
            # 但 revert 时恢复失败的条目继续重试（那是完成 revert，不是施加省电档）
            if state_has_actions; then
              session_leave
            fi
            return 0
          fi
          # 省电档下只把 Hyprland 特效值做一次漂移纠正
          effects_sync
          return 0
        fi
        # 非省电档：上一轮离开时恢复失败的条目还留着 → 本轮继续重试（成功一条删一条）
        if state_has_actions; then
          session_leave
        fi
        return 0
      }

      # ── 子命令 ──────────────────────────────────────────────────────
      cmd_status() {
        local profile sig kw want cap band u
        profile="$(get_profile)"
        printf 'TLP 档位   : %s   (tlpctl get)\n' "''${profile:-读不到}"
        band="$(current_band)" || band=""
        printf '电量策略   : band=%s   (policy=%s: < %s 用电池→power-saver；>= %s 插电→balanced)\n' \
          "''${band:-无电池}" "$policy_enabled" "$power_saver_below" "$balanced_above"
        if [ -f "$band_file" ]; then
          printf '             state band=%s   (%s)\n' "$(cat "$band_file")" "$band_file"
        else
          printf '             state band=未记录   (%s)\n' "$band_file"
        fi
        if cap="$(battery_capacity)"; then
          if ac_online; then
            printf 'AC/电量    : 插电    %s%%\n' "$cap"
          else
            printf 'AC/电量    : 用电池  %s%%\n' "$cap"
          fi
        else
          printf 'AC/电量    : 探测不到电池\n'
        fi
        printf 'darkman    : %s\n' "$(darkman get 2>/dev/null || echo 未运行)"
        if sig="$(hypr_sig)"; then
          printf 'Hyprland   : %s\n' "$sig"
          while read -r kw want; do
            [ -n "$kw" ] || continue
            printf '  %-32s 当前=%-16s 省电档目标=%s\n' "$kw" "$(hypr_get "$sig" "$kw")" "$want"
          done <<< "$effects_values"
        else
          printf 'Hyprland   : 无运行实例（特效部分跳过）\n'
        fi
        for u in $pause_units; do
          [ -n "$u" ] || continue
          printf '用户单元   : %-24s %s\n' "$u" "$(systemctl --user is-active "$u" 2>/dev/null || true)"
        done
        printf 'state      : %s\n' "$state_file"
        if [ -f "$state_file" ]; then
          sed 's/^/  /' "$state_file"
        else
          printf '  （尚无 state）\n'
        fi
        return 0
      }

      cmd_mode() {
        local want="''${1:-}" profile
        profile="$(get_profile)"
        if [ -z "$want" ]; then
          printf '当前档位: %s（可用: %s）\n' "''${profile:-读不到}" "$profiles"
          return 0
        fi
        case " $profiles " in
          *" $want "*) ;;
          *)
            printf '未知档位: %s（可用: %s）\n' "$want" "$profiles" >&2
            exit 2
            ;;
        esac
        if ! set_profile "$want"; then
          die "设档失败（tlp-pd 没在跑？）"
        fi
        printf '档位 -> %s（tlpctl set）\n' "$want"
        session_dispatch "$want"
      }

      case "''${1:-apply}" in
        run)
          # 定时器入口：两个步骤都不允许因为外部命令失败而中断整轮
          policy_step || warn "电量策略步骤失败，继续对齐会话层"
          session_step || warn "会话层对齐步骤失败"
          ;;
        apply)
          profile="$(get_profile)"
          if [ -z "$profile" ]; then
            die "读不到 TLP 档位（tlp-pd 没在跑？）"
          fi
          session_dispatch "$profile"
          ;;
        revert)
          profile="$(get_profile)"
          session_leave
          state_set profile "''${profile:-balanced}"
          # revert 的意思就是「现在别动我的桌面」：在档位再次变化（或显式 mode/apply）之前
          # 不再自动施加/纠正会话层动作，否则 30s 后定时器就会把它推翻
          state_set session paused
          log "已恢复：Hyprland 特效与用户单元（darkman 按设计不动）"
          log "注意：当前档位仍是 ''${profile:-未知}，在档位再次变化前不会重新应用（已暂停会话层）"
          ;;
        status) cmd_status ;;
        mode)
          shift 2>/dev/null || true
          cmd_mode "''${1:-}"
          ;;
        help|-h|--help) usage ;;
        *)
          usage
          exit 2
          ;;
      esac
    '';
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
