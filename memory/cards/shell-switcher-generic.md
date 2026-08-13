---
id: shell-switcher-generic
type: decision
tags: [shell-switcher, cli, generic, config]
date: 2026-08-13
---

# shell-switcher 通用化：默认 shell 由配置指定

## 问题
shell-switcher 最初硬编码 `DEFAULT_SHELL = "noctalia"`（回退、boot、help 都依赖它），这是本机 shell 名。用户要求：shell-switcher 必须是**通用切换器**，不是只适配本机环境的软件。

## 决策
- 移除硬编码默认 shell；`config.toml` 加可选 `default` 字段（boot 无 current 标记 / 切换失败回退时使用，缺省取第一个 `[[shell]]`）
- 无配置时明确报错（`no_shells`，提示 config 路径），不静默用内置默认
- 本地适配（`default = "noctalia"`）放在 NixOS 配置层（`home/hyprland/shell-switcher.nix`），工具本身零本地假设
- help 文本去本地化（"由你的配置声明"而非"NixOS 仓库"）

## Why
工具层 vs 配置层边界：通用工具的本地值（默认 shell、shell 列表）应来自用户配置而非代码常量。硬编码会让其他环境无法使用，也违背"托管 GitHub 给他人用"的目标。

## How to apply
- 给 shell-switcher 加功能时，不要引入具体 shell/compositor 名字作为常量
- 本地值放 NixOS 仓库；改默认 shell 只改 config.toml 的 `default`
- 工具缺配置时要明确报错，不做本地假设

相关: [[nix-flake-tracked-files]] | wiki/desktop/shell-switcher.md
