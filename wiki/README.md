# Wiki — NixOS 配置操作手册

本目录是操作手册，回答「**怎么用**」。配置背后的「**为什么**」见 [`../memory/INDEX.md`](../memory/INDEX.md) 决策记忆。故障排查也在这里，每个文档末尾附排查节。

## 桌面环境

| 文档 | 内容 |
|------|------|
| [hyprland.md](hyprland.md) | Hyprland 窗口管理器：按键、手势、工作流 |
| [noctalia.md](noctalia.md) | Noctalia Shell 桌面面板：控制中心、壁纸、配色 |
| [shell.md](shell.md) | Shell 环境：fish/bash、别名、starship、zellij、ghostty |
| [darkmode.md](darkmode.md) | 深色模式调度 |

## 网络与代理

| 文档 | 内容 |
|------|------|
| [mihomo.md](mihomo.md) | Mihomo TUN 代理：架构、WebUI、故障排查、nix 下载慢 |
| [litellm.md](litellm.md) | LiteLLM AI 代理：模型映射、健康检查 |

## 开发工具

| 文档 | 内容 |
|------|------|
| [nvim.md](nvim.md) | Neovim：配置、快捷键、LSP |

## 文件与办公

| 文档 | 内容 |
|------|------|
| [yazi.md](yazi.md) | Yazi 文件管理器：按键、插件、主题 |
| [distrobox.md](distrobox.md) | Distrobox 容器（arch + ubuntu） |
| [bottles-offline-workaround.md](bottles-offline-workaround.md) | Bottles 离线模式 workaround |

## 规范与约束

| 文档 | 内容 |
|------|------|
| [constraints.md](constraints.md) | NixOS 配置约束与惯例（overlay/override/import 选择、去重规则等） |

## 归档

- [`superpowers/specs/`](superpowers/specs/) — 设计文档（含本 wiki 与 memory 的迁移设计）
