---
id: portal-gtk-dangling-symlink
type: decision
tags: [fcitx5, portal, darkmode, troubleshooting]
date: 2026-08-06
---

# portal-gtk 无法激活导致 fcitx5 浅色皮肤

## 问题
全局是深色模式（dconf `prefer-dark`），但 fcitx5 候选窗皮肤一直是浅色。portal 查询 `color-scheme` 报错「未找到请求的设置」。

## 根因
`~/.config/systemd/user/xdg-desktop-portal-gtk.service` 是一个 **dangling symlink**：
- 指向 `/nix/store/c4qd650...`（已被 nix GC 清理）
- user systemd 搜索路径里 `~/.config/systemd/user` 排在 `/etc/systemd/user` 前面
- systemd 读到 dangling → unit not-found → D-Bus 无法激活 `org.freedesktop.impl.portal.desktop.gtk`
- portal Settings backend 缺失 → fcitx5 的 classicui 查 `color-scheme` 失败 → `isDark_` 默认 false → 浅色皮肤

日志特征：`Could not activate remote peer 'org.freedesktop.impl.portal.desktop.gtk': activation request failed: unknown unit`

## 修复
```bash
rm ~/.config/systemd/user/xdg-desktop-portal-gtk.service  # 删 dangling symlink
systemctl --user daemon-reload
systemctl --user start xdg-desktop-portal-gtk
```
删掉后 systemd fallback 到 `/etc/systemd/user/` 的正确 unit。验证：`busctl --user call ... ReadOne ss org.freedesktop.appearance color-scheme` 返回 `v u 1`（dark）。

## 为什么是 dangling
该 symlink 6月9日创建，指向的 nix store 路径被后续 rebuild 的 GC 清理。用户级 `~/.config/systemd/user` 里的 symlink 不由 nix 管理（NixOS 只写 `/etc/systemd/user`），GC 后残留。

## How to apply
- fcitx5 深色/浅色联动依赖 portal-gtk 正常激活。排查「应用不跟随深色」先检查 `systemctl --user status xdg-desktop-portal-gtk` 是否 running，以及 `busctl ... color-scheme` 是否返回 dark
- `~/.config/systemd/user` 下的 symlink 若指向已 GC 的 store 路径，直接删除，systemd 会 fallback 到 `/etc/systemd/user`
- mellow 主题通过 `i18n.inputMethod.fcitx5.settings.addons.classicui.globalSection` 配置：`Theme=mellow-wechat, DarkTheme=mellow-wechat-dark, UseDarkTheme=True`（portal 已修后标准写法）

相关: [[wiki-memory-layering]] | [[nix-search-before-manual]]
