---
title: Token Monitor
category: dev
tags: [ai, token-monitor, distrobox, autostart]
updated: 2026-10-28
---

# Token Monitor

Token Monitor 在现有 `arch` Distrobox 中运行，向 Noctalia 插件提供额度和使用情况。
应用、启动参数和 desktop 文件由 Arch 容器维护，通过 Distrobox 导出菜单入口与图标。
Nix 不管理此应用的安装、菜单或登录自启；Hyprland 的窗口尺寸规则仍属于桌面配置。

## 登录自启

容器内包提供 `/usr/share/applications/token-monitor.desktop`。
用户级副本保存在容器的 `~/.local/share/applications/token-monitor.desktop`，其中启动行为：

```ini
Exec=/usr/bin/env CODEX_HOME=/home/lishangshui/.codex /usr/bin/token-monitor --ozone-platform=wayland %U
Icon=token-monitor
```

修改该副本后，从宿主以普通用户调用容器中的导出工具：

```bash
distrobox enter arch -- distrobox-export --app /home/lishangshui/distrobox/arch/.local/share/applications/token-monitor.desktop --export-label none
```

Distrobox 生成宿主 `~/.local/share/applications/arch-token-monitor.desktop`，
并复制应用自带的蓝底白色 Σ 图标到宿主用户图标目录。
登录自启通过宿主 `~/.config/autostart/arch-token-monitor.desktop`
链接到该导出文件，Hyprland 的 UWSM、原生 niri-session 与 GNOME 负责执行。
容器停止时由 Distrobox 启动；应用的账号、Hub 密钥和窗口设置继续保存在容器 home。

若在托盘菜单中主动退出，可在桌面启动器搜索 **Token Monitor** 重新启动。
切换 Noctalia 与 Caelestia 不会重新执行图形登录自启。
包升级后若需同步上游 desktop 的其他字段，先更新容器用户级副本，再重新导出。

从旧 Nix 入口迁移时，旧的 `token-monitor-distrobox.desktop` 自启链接已撤下并备份到
`~/.local/state/token-monitor-migration/`。宿主应用目录保留同名 `Hidden=true` 条目，
用于隐藏尚在当前系统 generation 中的旧菜单入口；下次手动应用 Nix 配置后旧包会退出配置。

## 托盘与窗口尺寸

在 Token Monitor 中启用 **显示托盘图标** 和 **仅托盘显示（Tray-only mode）**。
仅托盘模式会在应用启动后隐藏窗口，保留托盘和 Hub。

1. 点击 Token Monitor 托盘图标，打开弹窗。
2. 切换到其他窗口，Token Monitor 失焦后隐藏回托盘。
3. 再次点击图标，重新显示窗口。

Hyprland 为 `token-monitor` 保留两种尺寸记忆，不强制浮动，
也不改写或抑制应用的最大化行为：

- 原生 Wayland 浮动窗口：`persistent_size` 保留调整后的宽高。
- 滚动平铺窗口：收回托盘时记录列宽比例，重新打开并获得焦点时恢复。
  高度继续由布局和同列窗口分配；重新打开不会重建原来的同列组合。

平铺记忆保存的是布局列宽比例，避免把布局自动调整后的屏幕宽度记成用户尺寸。
单个平铺窗口按 [Hyprland 滚动布局策略](../desktop/hyprland.md#滚动布局-scrolling-layout)
默认居中显示；回到单窗状态或重载配置时恢复默认尺寸，已有的列宽记忆机制仍用于适用的多列情形。
失焦隐藏继续由 Token Monitor 的仅托盘模式负责。
浮动记忆保留在当前 Hyprland 会话中；平铺记忆保留至配置重载或注销。
重新启动桌面后的尺寸恢复仍取决于应用自身的保存行为。

当前 Hyprland 通过点击或快捷键切换焦点，鼠标移过其他窗口不会转移焦点。
应用设置页等需要持续交互时，保持焦点在弹窗内；点击其他窗口可能触发收回。

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
cat ~/.local/share/applications/arch-token-monitor.desktop
readlink ~/.config/autostart/arch-token-monitor.desktop
distrobox list
podman exec arch pacman -Q token-monitor-bin
```

检查 Hub 是否监听：

```bash
ss -ltnp '( sport = :17321 )'
```

| 现象 | 排查 |
| --- | --- |
| 启动器找不到应用 | 在 Arch 内重新执行 Distrobox 导出，搜索 `Token Monitor` |
| 启动器显示通用齿轮 | 检查导出入口的 `Icon=token-monitor` 和宿主 `~/.local/share/icons/hicolor/512x512/apps/token-monitor.png` |
| 登录后没有托盘图标 | 确认 `arch` 存在、应用已安装，并检查桌面会话的自启日志 |
| 平铺时没有恢复原尺寸 | 确认已应用并重载新配置；调整列宽后收回再打开。单窗回到默认 75% 居中尺寸，多窗高度仍由布局决定 |
| 点击图标后很快消失 | 检查焦点是否转到其他窗口；仅托盘模式会在失焦时隐藏 |
| 额度停止更新 | 确认应用仍运行、Host hub 已启用，再使用插件的 Test connection |
| 容器重建后程序缺失 | 在容器内恢复 `token-monitor-bin` 并重新导出 |

## 相关链接

- [Distrobox](distrobox.md)
- [Hyprland](../desktop/hyprland.md)
- [Noctalia](../desktop/noctalia.md)
- [Token Monitor 上游](https://github.com/Javis603/token-monitor)
