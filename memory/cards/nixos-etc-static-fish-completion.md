---
id: nixos-etc-static-fish-completion
type: constraint
tags: [nixos, home-manager, fish, completion]
date: 2026-08-13
---

# NixOS /etc/static 固化丢 fish/zsh vendor 补全目录

## 问题
NixOS 把 `/etc/profiles` 固化成 `/etc/static/profiles/...`（只读）时，**只保留 bash-completion 目录，丢掉 fish/zsh 的 `vendor_completions.d` / `site-functions`**。home.packages 里包自带的 fish/zsh 补全（在 `$out/share/` 里）因此没进 profile，fish/zsh 扫不到，补全静默失效。

## 决策
- fish 补全显式装到 `~/.config/fish/completions/`（`$fish_complete_path` 第一项，一定加载），与 howdy/hyprctl/hyprland 补全同模式（`home/env/shell.nix` 手动声明）
- bash 补全走 profile 的 bash-completion（固化保留），无需处理

## Why
fish 的补全搜索路径包含 `/etc/profiles/.../share/fish/vendor_completions.d`，但固化后该目录不存在 → 补全静默失效。本机 fish 补全惯例就是 `~/.config/fish/completions/`。

## How to apply
- 给 home.packages 加带 fish 补全的包时，补全不生效先查 `ls ~/.config/fish/completions/`；需要时用 `xdg.configFile."fish/completions/<pkg>.fish".source` 显式安装
- zsh 同理（site-functions），本机 zsh 未装暂未处理

相关: [[shell-switcher-generic]] | wiki/desktop/shell-switcher.md
