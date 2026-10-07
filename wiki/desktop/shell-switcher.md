---
title: 桌面 Shell 切换
category: desktop
tags: [shell-switcher, shell, noctalia, caelestia, systemd]
updated: 2026-10-07
---

# 桌面 Shell 切换指南

## 概览

本机有 2 个**互斥**的桌面 shell：它们都抢 `org.freedesktop.Notifications` DBus、都画顶栏，**不能同时跑**。shell-switcher 负责运行时切换，保证同一时刻只有一个 shell 在跑。

所有 shell 都是 systemd user service（挂 `graphical-session.target` 上下文），由 `home/de/shell-switcher.nix` 声明切换映射，切换器二进制来自 flake input（`github:Shangshui0302/shell-switcher`）。

## 可用 shell

| Shell | 定义文件 | 默认启动 | 说明 |
|-------|----------|----------|------|
| **noctalia** | `home/de/noctalia.nix` | 默认选择 | 由 `shell-switcher-boot.service` 拉起，也是启动失败时的回退 |
| **caelestia** | `home/de/caelestia-shell.nix` | ❌ | caelestia-dots，依赖面大（强制 quickshell-git 外部源） |

两个 shell 的 service `WantedBy` 均置空，**只由统一启动入口与切换器启停**，避免同时激活。

## 常用操作

```bash
shell-switcher list               # 列出可用 shell（来自 config.toml）
shell-switcher current            # 显示当前 active 的 shell（无则 none）
shell-switcher set caelestia      # 切到 caelestia
shell-switcher set noctalia       # 切回 Noctalia
shell-switcher boot               # 仅尝试启动保存的 shell；登录服务另有失败回退
```

切换后新 shell 立即接管顶栏；旧 shell 进程被整个 cgroup 终止。

## 从启动器切换（desktop entries）

`home/de/shell-switcher.nix` 用 `xdg.desktopEntries` 声明两条 entry，方便直接在 launcher 里点：

| 条目名 | Exec |
|---|---|
| `Noctalia Shell` | `systemd-run --user --scope --collect -- shell-switcher set noctalia` |
| `Caelestia Shell` | `systemd-run --user --scope --collect -- shell-switcher set caelestia` |

**为什么必须套 `systemd-run --scope`**：launcher 是由 shell 自己的 service 派生的进程，属于 `set` 要停掉的那个 cgroup；而 `set` 在 stop 阶段**阻塞等待**所有 shell 变 inactive。不套壳时该进程会被 `KillMode=control-group` 的 SIGTERM 连带杀掉，只完成"停"、没走到"启"，结果是新旧两个 shell 全 inactive、marker 不变（journal 里表现为 `Stopped Caelestia Shell Service` 之后没有任何 noctalia 启动记录）。套进独立 scope 后进程移出该 cgroup，停旧 shell 不再影响它。

- `xdg.desktopEntries` 是通过 **`home.packages`（hiPrio）** 装进 profile 的 `share/applications`，**不是**写 `~/.local/share/applications`——排查时别找错目录。
- 不需要包装脚本：`set` 靠 `HYPRLAND_INSTANCE_SIGNATURE` / `NIRI_SOCKET` 做会话防呆，这两个变量由 uwsm 写进 systemd 用户环境（`systemctl --user show-environment` 可见），launcher 子进程能继承。
- 图标：Noctalia 的图标在它自己的包内、没进 profile，所以按绝对路径引用；Caelestia 只有 `share/caelestia-shell/assets/logo.svg` 资产，故用 `xdg.dataFile` 装成 `~/.local/share/icons/hicolor/scalable/apps/caelestia.svg`（`~/.local/share/icons` 在 XDG 图标搜索路径内），entry 里写裸名 `caelestia`。

## 切换机制（`set <name>` 内部流程）

1. **检测 compositor**：非 Hyprland/niri 会话直接拒绝（防呆）。
2. **幂等短路**：目标已在跑且无其他 shell 在跑 → 仅更新 current 标记，不做操作。
3. **stop 所有 shell**：逐个 `systemctl --user stop`，轮询确认全部 inactive（**10s 超时**，超时放弃切换并回退默认）。
4. **启动目标**：`systemctl --user start`，轮询进入 active（**15s 超时**）。
5. **写 current 标记**：`~/.config/shell-switcher/current` 记录当前 shell，供 `boot` 读取。

任一步失败**自动回退默认 shell（noctalia）**。

## 配置

`~/.config/shell-switcher/config.toml`（Nix 生成，`home/de/shell-switcher.nix`），`default` 指定默认 shell（boot 无 current 标记 / 切换失败回退时使用，缺省取第一个），`[[shell]]` 声明 name → systemd service 映射：

```toml
default = "noctalia"    # 默认 shell

[[shell]]
name = "noctalia"
service = "noctalia.service"    # 由统一入口启动

[[shell]]
name = "caelestia"
service = "caelestia.service"
```

fish 补全由 `home/de/shell-switcher.nix` 显式装到 `~/.config/fish/completions/`：NixOS 的 `/etc/static` 固化 profile 不暴露 fish 的 `vendor_completions.d` 目录，故显式安装（与 hyprctl/hyprland 补全同模式）。bash 补全走 profile 的 `bash-completion`（固化保留）。

新增可切换 shell 时：定义它的 service（`wantedBy` 置空）+ 在 config.toml 加一条 `[[shell]]` 映射。

Caelestia 会自动保存 `~/.config/caelestia/shell.json`，而 Home Manager 的声明式文件默认是只读链接。`caelestia.service` 启动前会把该链接解引用为可写副本；Home Manager 通过 `xdg.configFile."caelestia/shell.json".force = true` 在激活时直接覆盖这个运行时文件，不再创建会冲突的 `.backup` / `.hm-backup`。因此运行时改动要先同步回 Nix，下一次激活会以 Nix 配置为准。

## 快捷键兼容层

Hyprland 的 shell 相关快捷键统一调用 `desktop-shell-action`，它按当前 active service 分发到对应 shell，因此切换后无需更换快捷键。工作区总览快捷键由各 compositor 原生处理，不经过此兼容层：

- `Super + Space`：打开启动器
- `Super + K`：打开控制中心（Caelestia 的 utilities drawer）
- `Super + ,`：打开设置（Caelestia 的 Nexus）
- `Super + C`：剪贴板历史 —— Noctalia 面板；Caelestia 用 `caelestia clipboard`（`cliphist` + `fuzzel`）
- `Super + Shift + C`：删除剪贴板条目 —— Noctalia `clipboard-clear`；Caelestia `caelestia clipboard -d`
- `Super + Shift + L`：锁屏 —— Noctalia `session lock`；Caelestia `shell lock lock`
- `Super + Shift + Print`：区域截图并复制 —— Noctalia `screenshot-region`；Caelestia AreaPicker
- 媒体键（`XF86AudioPlay/Next/Prev/Stop`）：Noctalia `media <action>`；Caelestia `shell mpris <fn>`
- `Super + Tab`：Hyprland 使用 ScrollOverview；niri 使用原生 `toggle-overview`
- 亮度键：两套 shell 都按 5% 步进

Caelestia 独有、无通配分支的动词（Noctalia 侧 `exit 2`，按键无响应）：`dashboard`、`sidebar`、`session`、`showall`、`record`。

剪贴板历史由 Home Manager 的 `cliphist.service` 常驻采集（`wl-paste --watch cliphist store`），和 shell 切换无关——两个 shell 共用同一个历史库。壁纸仍统一交给 waypaper + Matugen 管线。

## 启动流程

- **唯一入口**：`shell-switcher-boot.service`（`home/de/shell-switcher.nix`）挂 `graphical-session.target`，执行 `shell-switcher boot` 读 `~/.config/shell-switcher/current` 标记，启动上次选的 shell。两个 shell 的 unit **都不再设 `Install.WantedBy`**（Noctalia 已移除，Caelestia 本来就是空的），所以谁是 active 完全由这个入口决定。
  - 为什么不能让 Noctalia 自己挂 `graphical-session.target`：uwsm 会话下该 target 会**并行**拉起所有 `WantedBy` 单元，而 shell-switcher 只停"它自己启动的"那个 shell，于是 Noctalia 会留下来与 Caelestia 并存（实测到的双 shell）。去掉自动拉起后不再有竞争窗口。
  - 无标记时使用 `config.toml` 的 `default`（= noctalia）。
  - 保存的 shell 启动失败时，服务包装器执行 `shell-switcher set noctalia`，清理其他 shell 并将 current 标记改为 Noctalia；默认 shell 也失败时才重试服务。直接运行裸 `shell-switcher boot` 没有这层回退。
- **rebuild 后同样收敛**：`nixos-rebuild switch` 会重启 `graphical-session.target`，上述服务随之重跑，所以不需要手工 `shell-switcher set <name>`。标记文件 `~/.config/shell-switcher/current` 不是声明式管理的，HM 激活器只清理自己命名空间下的文件，标记得以保留（要重置就删掉它）。
- Noctalia 的 unit 带 `SuccessExitStatus=143`：切换时被 SIGTERM 停掉（退出码 143）不该被 systemd 记成 failed。
- 注意该服务 `RemainAfterExit=yes`：处于 active(exited) 时 `systemctl --user start` 是 no-op，手工重测要用 `restart`。

## 防呆与故障排查

| 现象 | 原因 / 处理 |
|------|-------------|
| `set` 报"非 Hyprland/niri 会话" | 必须在 Hyprland/niri 里的终端运行（依赖 `HYPRLAND_INSTANCE_SIGNATURE` / `NIRI_SOCKET`） |
| `set` 报"未知 shell" | 先 `shell-switcher list` 确认名字，config.toml 是否声明 |
| 切换后双顶栏 / 通知异常 | 某 shell 未被 stop。`systemctl --user status noctalia caelestia` 查，手动 `systemctl --user stop <卡住的>` |
| 切换失败自动回退 noctalia | `systemctl --user status <目标>` 看日志（`journalctl --user -u <service> -e`） |
| Caelestia 报 `failed to write config` | 执行一次 HM/NixOS rebuild，再用 `shell-switcher set noctalia`、`shell-switcher set caelestia` 重启目标 service；无需手动删除备份文件，若仍失败检查 `systemctl --user status caelestia` 和 `journalctl --user -u caelestia -e` |
| fish 补全出现 `KeyError: 'variant'` 或查找 `schemes/matugen` 失败 | Matugen 生成的 `~/.local/state/caelestia/scheme.json` 必须含 CLI 支持的 `name=dynamic`、`flavour=default`、`variant=content` 和当前深浅 `mode`。应用修正后的 Nix 配置，再运行 `~/.local/bin/theme-apply "$(darkman get)"` 重新生成；用 `caelestia scheme list -f`、`caelestia scheme list -m` 检查 |
| 想清理 current 标记 | 删 `~/.config/shell-switcher/current`（下次统一启动入口默认选择 Noctalia） |

## 相关链接

- [Noctalia](noctalia.md) — 默认 shell，systemd 拉起（非 compositor autostart）；2026-08-13 清理过 validate warnings，见其维护注记
- [Hyprland](hyprland.md) — 桌面 shell 切换的入口说明
- [wiki 首页](../README.md)
