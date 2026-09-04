---
title: Wiki 首页
category: 顶层
tags: [index, moc]
updated: 2026-09-04
---

# Wiki — NixOS 配置操作手册

本目录是操作手册，回答「**怎么用**」。配置背后的「**为什么**」见 [`../memory/INDEX.md`](../memory/INDEX.md) 决策记忆。故障排查也在这里，每个文档末尾附排查节。

来源映射清单 [`_sources.yaml`](_sources.yaml) 是 wiki 文档与 nix 模块 / memory 卡之间的**唯一绑定表**，驱动 doc-sync hook。

## 项目总览

| 文档 | 内容 |
|------|------|
| [项目概述](overview.md) | 项目简介、技术栈、核心组件、快速开始 |

## 系统架构 `architecture/`

| 文档 | 内容 |
|------|------|
| [架构总览](architecture/index.md) | Flake → host/home 装配、引导服务加载流程 |
| [Flake 配置管理](architecture/flake.md) | Flake inputs、锁定策略、unstable 分支 |
| [主机系统架构](architecture/host.md) | 启动流程、硬件抽象、引导、用户、locale |

## 桌面环境 `desktop/`

| 文档 | 内容 |
|------|------|
| [Hyprland](desktop/hyprland.md) | 窗口管理器：按键、手势、工作流、滚动布局 |
| [Niri](desktop/niri.md) | 滚动平铺合成器：uwsm 启动、窗口流 |
| [GNOME](desktop/gnome.md) | 完整桌面：specialisation 变体，GDM 登录 |
| [Fcitx5 输入法](desktop/fcitx5.md) | Rime 引擎、垂直候选窗、深浅色联动 |
| [Noctalia Shell](desktop/noctalia.md) | 桌面面板：控制中心、壁纸、配色、锁屏 |
| [桌面 Shell 切换](desktop/shell-switcher.md) | 运行时切换 shell：Noctalia/Caelestia |
| [Shell 环境](desktop/shell.md) | fish/bash、别名、starship、zellij、foot |
| [深色模式架构](desktop/darkmode.md) | 深色调度、dconf/qt5ct/portal 分发 |
| [GNOME Keyring](desktop/keyring.md) | 凭据存储：PAM 解锁、Electron 应用、故障排查 |

## 生产力 `productivity/`

| 文档 | 内容 |
|------|------|
| [办公软件套件](productivity/office.md) | LibreOffice、OnlyOffice、Obsidian、Markdown 编辑器 |
| [图像与视频工具](productivity/graphics.md) | gThumb、GIMP、Kdenlive、Glaxnimate、Blender |
| [Yazi 文件管理器](productivity/yazi.md) | 文件管理器：按键、插件、主题 |

## 开发与工具 `dev/`

| 文档 | 内容 |
|------|------|
| [Neovim](dev/nvim.md) | 编辑器：按键、插件、LSP、工作流 |
| [VS Code](dev/vscode.md) | VS Code 集成、AI 工具、扩展 |
| [Nix 手工打包](dev/nix-packaging.md) | `$nix-package`、本地派生、独立构建和验证流程 |
| [Distrobox](dev/distrobox.md) | 容器（arch + ubuntu）：创建、进入、导出 |
| [Bottles 离线方案（历史）](dev/bottles-offline-workaround.md) | 历史 Flatpak Bottles 离线索引接管方案 |

## 娱乐 `leisure/`

| 文档 | 内容 |
|------|------|
| [游戏平台](leisure/gaming.md) | Steam、MangoHud、32-bit 图形库、Flatpak 游戏 |
| [媒体播放](leisure/media.md) | mpv、网易云、OBS、loupe、animeko、ani-cli、Kazumi、cliamp |

## 网络与代理 `networking/`

| 文档 | 内容 |
|------|------|
| [Mihomo 代理](networking/mihomo.md) | TUN 代理：架构、WebUI、故障排查、nix 下载慢 |

## 安全与隐私 `security/`

| 文档 | 内容 |
|------|------|
| [安全总览](security/index.md) | SOPS、PAM、用户权限、网络安全概览 |
| [SOPS 机密管理](security/sops.md) | age 加密、secrets.yaml、服务注入 |
| [PAM — 可插拔认证模块](security/pam.md) | Linux 认证框架：模块、阶段、与 keyring 的关系 |

## 系统基础

| 文档 | 内容 |
|------|------|
| [系统服务](services.md) | PipeWire、蓝牙、CUPS、电源管理、fstrim、OneDrive 等聚合 |
| [部署与维护](deployment.md) | rebuild、新机首次部署、密钥、升级回滚、备份 |
| [故障排除](troubleshooting.md) | 聚合页：链接各文档排查节 + issues/archived |
| [约束与惯例](constraints.md) | overlay/override/import 选择、去重规则、sudo 规则等 |

## 归档

- [`superpowers/specs/`](superpowers/specs/) — 设计文档（含本 wiki 与 memory 的迁移设计）
