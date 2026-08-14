---
id: waypaper-nix-integration
type: constraint
tags: [waypaper, nix, home-manager, wallpaper]
date: 2026-08-15
---

# waypaper 集成 Nix 的四个坑

## 问题
waypaper 接入 Nix（config.ini 声明式管理）踩了 4 个坑，每个都导致切壁纸链路失效。

## 决策 / 坑
1. **config.ini 必须可写**：Nix symlink 只读 → waypaper 报 "Could not save config file" 且 post_command 不触发。用 `home.activation` 复制为普通可写文件。
2. **section 必须 `[Settings]`（大写 S）**：waypaper `config.get("Settings", ...)` 大小写敏感，`[settings]` 小写读不到 post_command。
3. **post_command 必须固定路径 wrapper**：waypaper 常驻进程缓存 post_command 并写回 config.ini；store hash 路径每次 rebuild 都变，会被覆盖成旧值。用 `~/.local/bin/wallpaper-theme` 固定路径 + activation 更新内容（路径稳定、内容每次执行读最新）。
4. **folder 要有默认值**：activation 只写 backend+post_command 会丢失 folder，waypaper 每次打开回退默认 Pictures 需重选。预设 `folder = ~/Pictures/Wallpapers`。

## Why
waypaper 是常驻 GUI 进程，读 config.ini 进内存、操作后写回；Nix 的声明式文件（只读 symlink + hash 路径）与之冲突，需要"固定路径 + 可写副本 + 关键字段预设"三者配合。

## How to apply
- 改 waypaper config 时，四个坑都要覆盖（可写、大写 section、固定路径 wrapper、folder 预设）
- post_command 永远指向 `~/.local/bin/wallpaper-theme`（内容由 activation 更新）

相关: [[matugen-wallpaper-theming]] | wiki/desktop/hyprland.md
