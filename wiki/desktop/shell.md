---
title: Shell 环境
category: desktop
tags: [shell, fish, bash, starship, zellij]
updated: 2026-08-20
---

# Shell 环境指南

本机使用 fish 作为默认 shell，bash 作为备选（带 ble.sh 增强），starship 作为统一提示符。

## Shell 选择

| Shell | 角色 | 特点 |
|-------|------|------|
| **fish** | 默认 | 语法高亮、自动建议、4 个插件 |
| **bash** | 备选 | ble.sh 语法高亮/补全、脚本兼容 |

终端模拟器：**foot**（系统级），默认启动 fish。ghostty 暂时禁用。

## 别名速查

两个 shell 共享相同别名：

| 别名 | 实际命令 | 说明 |
|------|----------|------|
| `ls` | `eza --icons=auto` | 彩色文件列表 + Nerd 图标 |
| `ll` | `eza -l --icons=auto` | 详细列表 |
| `la` | `eza -la --icons=auto` | 显示隐藏文件 |
| `lt` | `eza -T --icons=auto` | 树形展示 |
| `tree` | `eza -T --icons=auto` | 同上 |
| `cat` | `bat` | 语法高亮预览 |
| `grep` | `rg` | ripgrep 搜索 |
| `find` | `fd` | fd 查找文件 |
| `top` | `btop` | 系统监视器 |

## Starship 提示符

格式：`OS NixOS 用户@主机 📁路径 分支 状态 语言模块 时间 电池` + 换行 + `❯`

模块说明：

| 模块 | 显示内容 | 示例 |
|------|----------|------|
| `os` | NixOS Logo (蓝色) | `󱄅` |
| `username` | 用户名 (绿色) | `lishangshui` |
| `hostname` | 主机名 (蓝色) | `MechRevo-NixOS` |
| `directory` | 当前路径 (蓝色) | `📁~/myNixOSConfig` |
| `git_branch` | 分支名 (紫色) | `main` |
| `git_status` | 工作区状态 (黄色) | `+1 !2 ?3` |
| `git_metrics` | 增删行数 | `+10 -3` |
| `nix_shell` | Nix shell 状态 | `󱄅 pure/impure` |
| `python` | Python 版本+虚拟环境 | `󰌠 3.12 (.venv)` |
| `nodejs` | Node.js 版本 | ` 22.0` |
| `rust` | Rust 版本 | `󱘗 1.85` |
| `docker_context` | Docker 上下文 | `󰡨 default` |
| `time` | 当前时间 | `󰥔 14:30` |
| `battery` | 电池电量 | 颜色随电量变化 |
| `cmd_duration` | 命令耗时 | ≥2s 时显示 |
| `character` | 提示符 `❯` | 绿色(成功)/红色(失败) |

## Zellij

终端多路复用器，Catppuccin Mocha 主题。

```bash
zellij           # 启动
zellij attach    # 重新连接已有会话
```

常用快捷键见 Zellij 内置帮助 (`Ctrl+g` → `?`)。

## Ghostty 保留快捷键

大部分默认绑定已解除（让 Hyprland 管理），仅保留以下：

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+Shift+C` | 复制到剪贴板 |
| `Ctrl+Shift+V` | 从剪贴板粘贴 |
| `Ctrl+Shift+F` | 搜索 |
| `Ctrl+Shift+I` | 打开检查器 |
| `Ctrl+Shift+P` | 命令面板 |
| `Ctrl++` | 放大字号 |
| `Ctrl+-` | 缩小字号 |
| `Ctrl+0` | 重置字号 |
| `Ctrl+Shift+PageUp` | 跳到上一条提示符 |
| `Ctrl+Shift+PageDown` | 跳到下一条提示符 |

Ghostty 配置：`Catppuccin Mocha` 深色主题，字号 14，滚动限制 10000 行。

## Fish 插件

| 插件 | 功能 |
|------|------|
| `autopair` | 自动补全括号、引号 |
| `done` | 长时间命令完成后发送通知 |
| `grc` | 给 `ping`/`traceroute`/`df` 等输出上色 |
| `colored-man-pages` | man 手册语法高亮 |

## Fish 命令补全

补全文件由 Home Manager 显式安装到 `~/.config/fish/completions/`。这样不依赖 NixOS 固化 profile 中可能缺失的 `vendor_completions.d`。

- `noctalia`：主命令静态补全，`msg` 子命令从当前 CLI 帮助动态读取
- `darkman`：使用包自带的 Fish 补全
- `hyprctl`：根据当前 Hyprland 的 `hyprctl --help` 生成命令列表，避免上游生成文件的错位描述
- `hyprland`、`podman`、`howdy`、`shell-switcher`：同样放在用户补全目录

排查补全是否已加载：

```bash
ls ~/.config/fish/completions
fish -c 'complete -C "noctalia msg "'
fish -c 'complete -C "darkman "'
fish -c 'complete -C "hyprctl "'
```

如果目录中的文件已更新但当前终端仍无补全，重新打开 Fish；配置修改需要手动执行 `sudo nixos-rebuild switch --flake .`。

## Bash ble.sh 配置

- 语法高亮：内置命令绿色 (`#abe15b`)、可执行文件蓝色 (`#33adff`)、变量黄色 (`#ffd242`)
- `zoxide` 智能跳转（`z <关键词>`）
- 共享 fish 的所有别名

## Foot 桌面通知

fish 和 bash 均已配置：当命令执行超过 10 秒时，完成后自动弹出桌面通知。

通知通过 foot 的 OSC 777 序列触发，`foot-notify` 脚本调用 `notify-send` 显示通知，点击可聚焦 foot 窗口。

## 环境变量

系统 secrets 通过 sops-nix + age 加密管理（`host/secrets/secrets.yaml`），rebuild 时解密到 `/run/secrets/`。

**Distrobox**：`~/.local/bin` 加入 fish PATH（`fish_add_path`），承载 `distrobox-export` 导出的容器内 CLI 工具，宿主机可直接调用。

## 常用工作流

```bash
# 快速导航
z myNixOSConfig    # 跳转到配置目录
z Projects         # 跳转到项目目录

# 文件操作
la                 # 查看所有文件
lt                 # 树形查看目录结构
bat README.md      # 高亮预览文件

# 搜索
rg "search term"   # 全文搜索
fd "*.nix"         # 按文件名查找

# 解压
ouch x file.zip    # 通用解压
```

## 相关链接

- [Hyprland](hyprland.md) — `Super + Q` 启动 foot 终端
- [Noctalia](noctalia.md) — 应用启动器默认终端命令 foot
- [NixOS /etc/static 补全约束](../../memory/cards/nixos-etc-static-fish-completion.md) — Fish 补全显式安装到用户目录
- [wiki 首页](../README.md)
