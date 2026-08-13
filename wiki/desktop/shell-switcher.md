---
title: 桌面 Shell 切换
category: desktop
tags: [shell-switcher, shell, noctalia, dms, caelestia, persona, systemd]
updated: 2026-08-13
---

# 桌面 Shell 切换指南

## 概览

本机有 4 个**互斥**的桌面 shell：它们都抢 `org.freedesktop.Notifications` DBus、都画顶栏，**不能同时跑**。shell-switcher 负责运行时切换，保证同一时刻只有一个 shell 在跑。

所有 shell 都是 systemd user service（挂 `graphical-session.target` 上下文），由 `home/hyprland/shell-switcher.nix` 声明切换映射，切换器二进制来自 flake input（`github:Shangshui0302/shell-switcher`）。

## 可用 shell

| Shell | 定义文件 | 默认启动 | 说明 |
|-------|----------|----------|------|
| **noctalia** | `home/hyprland/noctalia.nix` | ✅ 自动 | 默认 shell，`WantedBy=graphical-session.target` 由 systemd 拉起 |
| **dms** | `host/hyprland/dms-shell.nix` | ❌ | DankMaterialShell，裁剪了监控/动态主题/音频波形/日历事件 |
| **caelestia** | `home/hyprland/caelestia-shell.nix` | ❌ | caelestia-dots，依赖面大（强制 quickshell-git 外部源） |
| **persona** | `home/hyprland/persona-shell.nix` | ❌ | 纯 QML 主题（`local-deriv/persona-quickshell.nix` 打包 + `qs -c`） |

非默认 shell 的 service `wantedBy` 均置空，**只由切换器启停**，避免与 Noctalia 同时激活。

## 常用操作

```bash
shell-switcher list               # 列出可用 shell（来自 config.toml）
shell-switcher current            # 显示当前 active 的 shell（无则 none）
shell-switcher set dms            # 切到 DMS
shell-switcher set noctalia       # 切回 Noctalia
shell-switcher boot               # 读 current 标记启动对应 shell（shell-starter 入口）
```

切换后新 shell 立即接管顶栏；旧 shell 进程被整个 cgroup 终止。

## 切换机制（`set <name>` 内部流程）

1. **检测 compositor**：非 Hyprland/niri 会话直接拒绝（防呆）。
2. **幂等短路**：目标已在跑且无其他 shell 在跑 → 仅更新 current 标记，不做操作。
3. **stop 所有 shell**：逐个 `systemctl --user stop`，轮询确认全部 inactive（**10s 超时**，超时放弃切换并回退默认）。
4. **启动目标**：`systemctl --user start`，轮询进入 active（**15s 超时**）。
5. **写 current 标记**：`~/.config/shell-switcher/current` 记录当前 shell，供 `boot` 读取。

任一步失败**自动回退默认 shell（noctalia）**。DMS 被 SIGTERM 停（退出码 143）在 systemd 里配了 `SuccessExitStatus=143`，不标 failed。

## 配置

`~/.config/shell-switcher/config.toml`（Nix 生成，`home/hyprland/shell-switcher.nix`），`default` 指定默认 shell（boot 无 current 标记 / 切换失败回退时使用，缺省取第一个），`[[shell]]` 声明 name → systemd service 映射：

```toml
default = "noctalia"    # 默认 shell

[[shell]]
name = "noctalia"
service = "noctalia.service"    # 唯一自动起的

[[shell]]
name = "dms"
service = "dms.service"
```

fish 补全由 `home/hyprland/shell-switcher.nix` 显式装到 `~/.config/fish/completions/`：NixOS 的 `/etc/static` 固化 profile 不暴露 fish 的 `vendor_completions.d` 目录，故显式安装（与 hyprctl/hyprland 补全同模式）。bash 补全走 profile 的 `bash-completion`（固化保留）。

新增可切换 shell 时：定义它的 service（`wantedBy` 置空）+ 在 config.toml 加一条 `[[shell]]` 映射。

## 启动流程

- **默认**：Noctalia 由 `WantedBy=graphical-session.target` 自动拉起，无需切换器介入。
- **重启后恢复上次切换**：`shell-switcher boot` 读 `current` 标记启动对应 shell（用于 compositor autostart / shell-starter 场景）。注意 `current` 标记不是声明式管理的，rebuild 不重置。

## 防呆与故障排查

| 现象 | 原因 / 处理 |
|------|-------------|
| `set` 报"非 Hyprland/niri 会话" | 必须在 Hyprland/niri 里的终端运行（依赖 `HYPRLAND_INSTANCE_SIGNATURE` / `NIRI_SOCKET`） |
| `set` 报"未知 shell" | 先 `shell-switcher list` 确认名字，config.toml 是否声明 |
| 切换后双顶栏 / 通知异常 | 某 shell 未被 stop。`systemctl --user status noctalia dms ...` 查，手动 `systemctl --user stop <卡住的>` |
| 切换失败自动回退 noctalia | `systemctl --user status <目标>` 看日志（`journalctl --user -u <service> -e`） |
| 想清理 current 标记 | 删 `~/.config/shell-switcher/current`（默认仍走 Noctalia 自动起） |

## 相关链接

- [Noctalia](noctalia.md) — 默认 shell，systemd 拉起（非 compositor autostart）；2026-08-13 清理过 validate warnings，见其维护注记
- [Hyprland](hyprland.md) — 桌面 shell 切换的入口说明
- [wiki 首页](../README.md)
