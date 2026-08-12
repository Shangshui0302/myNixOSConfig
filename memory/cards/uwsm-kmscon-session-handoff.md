---
id: uwsm-kmscon-session-handoff
type: decision
tags: [uwsm, kmscon, session, tty, de-switch, fcitx5, drm]
date: 2026-08-12
---

# TTY 下 DE 切换：kmscon/uwsm 会话管理与 DRM 交接

## 问题

从 kmscon TTY 登录后启动/切换 compositor，会遇到「compositor already running」「fcitx5 不自动启动」等诡异问题。根因在会话层协调机制，不在 compositor 本身。

## 机制（2026-08 排查结论）

- **DRM master 交接**：kmscon（`libseat=false` raw-VT）握着 DRM master 渲染 TTY。compositor 要接管必须让 kmscon 释放——通过 OSC 转义 `\033]setBackground\a`。官方工具 `kmscon-launch-gui` 封装了「setBackground → sleep 0.2 → 跑合成器 → setForeground」，裸跑 compositor（`start-cosmic`）会因 master 被占而失败。
- **uwsm 检测**：`uwsm check may-start` 检查 systemd user 的 `graphical-session*.target` 是否 active；active 即拒启 compositor（报 compositor already running）。
- **自带 session manager 的 DE 残留**：cosmic-session.target `BindsTo=graphical-session.target`，但退出只停自己的 target，`graphical-session.target` 保持 active → 堵住 uwsm。
- **fcitx5 autostart 依赖 uwsm**：fcitx5 由 `systemd-xdg-autostart-generator` 生成 `app-org.fcitx.Fcitx5@autostart.service`（`PartOf=graphical-session.target`），在 uwsm 激活会话时触发。绕过 uwsm 裸跑 compositor（`kmscon-launch-gui start-hyprland`）则 autostart 不触发 → fcitx5 不自动启动。

## 决策

TTY 切换 DE 的正确流程：**退出当前 → 清理残留 graphical-session target → `uwsm start <下一个>`**，不需要重启系统。优先选能走 uwsm 的 DE（Hyprland/niri）；自带 session manager 的 DE（cosmic 之类）与 uwsm 架构冲突，是残留误判的根源——这是当初卸载 cosmic 的架构原因之一。

## How to apply

- 切 DE 前清理残留：`systemctl --user stop graphical-session.target graphical-session-pre.target`
- 启动：`uwsm start hyprland.desktop`（自带 kmscon setBackground 协调 + autostart）
- 排查「compositor already running」：先 `systemctl --user status graphical-session.target` 看是否有残留
- fcitx5 不自动启动：确认走的是 uwsm 完整流程，别用 kmscon-launch-gui 裸跑 compositor
- GNOME 例外：走 GDM + specialisation（见 [[memory/cards/gnome-specialisation]]），不经 uwsm

相关: [[memory/cards/gnome-specialisation]]
