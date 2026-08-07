---
title: Wiki 首页
category: 顶层
tags: [index, moc]
updated: 2026-08-06
---

# Wiki — NixOS 配置操作手册

本目录是操作手册，回答「**怎么用**」。配置背后的「**为什么**」见 [`../memory/INDEX.md`](../memory/INDEX.md) 决策记忆。故障排查也在这里，每个文档末尾附排查节。

## 桌面环境 `desktop/`

| 文档 | 内容 |
|------|------|
| [Hyprland](desktop/hyprland.md) | 窗口管理器：按键、手势、工作流、滚动布局 |
| [Noctalia Shell](desktop/noctalia.md) | 桌面面板：控制中心、壁纸、配色、锁屏 |
| [Shell 环境](desktop/shell.md) | fish/bash、别名、starship、zellij、ghostty |
| [深色模式架构](desktop/darkmode.md) | 深色调度、dconf/qt5ct/portal 分发 |
| [GNOME Keyring](desktop/keyring.md) | 凭据存储：PAM 解锁、Electron 应用、故障排查 |

## 网络与代理 `networking/`

| 文档 | 内容 |
|------|------|
| [Mihomo 代理](networking/mihomo.md) | TUN 代理：架构、WebUI、故障排查、nix 下载慢 |

## 开发与工具 `dev/`

| 文档 | 内容 |
|------|------|
| [Neovim](dev/nvim.md) | 编辑器：按键、插件、LSP、工作流 |
| [Yazi 文件管理器](dev/yazi.md) | 文件管理器：按键、插件、主题 |
| [Distrobox](dev/distrobox.md) | 容器（arch + ubuntu）：创建、进入、导出 |
| [Bottles 离线韧性改造](dev/bottles-offline-workaround.md) | Flatpak Bottles 离线索引接管 |

## 系统基础

| 文档 | 内容 |
|------|------|
| [PAM — 可插拔认证模块](pam.md) | Linux 认证框架：模块、阶段、与 keyring 的关系 |
| [约束与惯例](constraints.md) | overlay/override/import 选择、去重规则、sudo 规则等 |

## 归档

- [`superpowers/specs/`](superpowers/specs/) — 设计文档（含本 wiki 与 memory 的迁移设计）
