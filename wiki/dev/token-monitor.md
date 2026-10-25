---
title: Token Monitor
category: dev
tags: [ai, token-monitor, distrobox, autostart]
updated: 2026-10-25
---

# Token Monitor

Token Monitor 在现有 `arch` Distrobox 中运行，向 Noctalia 插件提供额度和使用情况。
Home Manager 管理图形登录自启，应用版本继续由容器中的包管理器维护。

## 登录自启

应用本次 Nix 配置后，下次图形登录会通过 XDG 自启入口启动 Token Monitor。
Hyprland 的 UWSM、原生 niri-session 与 GNOME 负责执行桌面自启入口。

- 入口：`~/.config/autostart/token-monitor-distrobox.desktop`。
- 目标：已经存在的 `arch` Distrobox；容器停止时由 Distrobox 启动。
- 缺少 `arch` 时跳过并报告错误，不自动创建容器或安装软件。
- 程序：容器内 `/usr/bin/token-monitor`，采用原生 Wayland。
- Codex 数据：显式使用宿主 `~/.codex`。
- 应用的账号、Hub 密钥和窗口设置继续保存在容器 home。

这是普通桌面应用的登录自启，不额外添加崩溃重启守护。
若在托盘菜单中主动退出，可在桌面启动器搜索 **Token Monitor** 重新启动。
应用菜单和登录自启共用同一个容器启动入口。
切换 Noctalia 与 Caelestia 不会重新执行图形登录自启。

## 托盘弹窗

在 Token Monitor 中启用 **显示托盘图标** 和 **仅托盘显示（Tray-only mode）**。
仅托盘模式会在应用启动后隐藏窗口，保留托盘和 Hub。

1. 点击 Token Monitor 托盘图标，打开弹窗。
2. 调整到合适的窗口尺寸，稍等应用保存。
3. 切换到其他窗口，Token Monitor 失焦后隐藏回托盘。
4. 再次点击图标，应用沿用上次宽高并重新计算托盘附近的位置。

Hyprland 对 `token-monitor` 窗口应用浮动规则。
失焦隐藏和尺寸持久化由 Token Monitor 负责，不使用额外的窗口事件脚本。
浮动规则不设置固定宽高，避免每次显示时覆盖用户调整的尺寸。

当前 Hyprland 使用鼠标跟随焦点；鼠标进入另一窗口可能转移焦点，
因此也可能触发收回。应用设置页等需要持续交互时，保持焦点在弹窗内。

## Noctalia 连接

Token Monitor 中选择 **Settings → Sync method → Host hub on this device**。
应用的 **Local only** 模式不提供插件需要的 HTTP Hub。

- 本机 Hub：`http://127.0.0.1:17321`。
- 数据接口：只读 `/api/stats` 和 `/api/history`。
- 标准容器凭据位置：`~/distrobox/arch/.config/Token Monitor/credentials.json`。
- Noctalia 插件支持自动发现此目录，也可在高级设置中指定凭据文件。

`arch` 当前使用宿主机网络，因此本机插件不需要额外端口映射。
应用退出后 Hub 随之停止，插件会保留旧快照并显示连接状态。
登录自启不替代应用中的账号登录与 Host hub 设置。

## 检查与故障排查

查看自启入口和容器中的安装版本：

```bash
cat ~/.config/autostart/token-monitor-distrobox.desktop
distrobox list
podman exec arch pacman -Q token-monitor-bin
```

检查 Hub 是否监听：

```bash
ss -ltnp '( sport = :17321 )'
```

| 现象 | 排查 |
| --- | --- |
| 启动器找不到应用 | 确认已应用包含应用菜单入口的新配置，搜索 `Token Monitor` |
| 登录后没有托盘图标 | 确认 `arch` 存在、应用已安装，并检查桌面会话的自启日志 |
| 窗口仍被平铺 | 确认已应用新配置；原有窗口需先收回托盘再显示 |
| 点击图标后很快消失 | 检查焦点是否转到其他窗口；仅托盘模式会在失焦时隐藏 |
| 额度停止更新 | 确认应用仍运行、Host hub 已启用，再使用插件的 Test connection |
| 容器重建后程序缺失 | 在容器内恢复 `token-monitor-bin`；本模块只管理启动入口 |

## 相关链接

- [Distrobox](distrobox.md)
- [Hyprland](../desktop/hyprland.md)
- [Noctalia](../desktop/noctalia.md)
- [Token Monitor 上游](https://github.com/Javis603/token-monitor)
