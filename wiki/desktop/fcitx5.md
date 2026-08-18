---
title: Fcitx5 输入法框架
category: 桌面环境
tags: [fcitx5, rime, 输入法, wayland, 深色模式]
updated: 2026-08-13
---

# Fcitx5 输入法框架

本文说明本仓库如何在 NixOS + Home Manager 下启用并集成 Fcitx5：引擎与主题管理、中文输入方案、Wayland/Hyprland 集成、候选窗定制与常见排障。核心 + 变体差异集中在系统级 `host/base/desktop.nix`，用 `lib.optionals (!gnome)` 表达 Hyprland 专属 addons、`lib.mkIf (!gnome)` 控制 classicui（GNOME 走 kimpanel）；崩溃自恢复在用户级 `home/de/hyprland.nix`。

## 目录
1. [快速上手](#快速上手)
2. [系统级配置要点](#系统级配置要点)
3. [引擎与中文输入方案](#引擎与中文输入方案)
4. [主题与候选窗定制](#主题与候选窗定制)
5. [桌面集成与崩溃自恢复](#桌面集成与崩溃自恢复)
6. [架构总览](#架构总览)
7. [故障排查](#故障排查)
8. [配置速查](#配置速查)
9. [相关链接](#相关链接)

## 快速上手
Fcitx5 在系统构建后即随会话启动，无需额外操作：

- 应用通过环境变量自动接入 fcitx（GTK/Qt/SDL 统一）。
- 使用桌面环境快捷键（如 `Super+Space`）在中英文/输入法间切换。
- 首次使用建议运行 `fcitx5-configtool` 检查方案与顺序。

## 系统级配置要点
系统层在 `host/base/desktop.nix` 中完成以下工作：

- 全局环境变量将各类应用统一接入 fcitx：
  - `GTK_IM_MODULE=fcitx`
  - `QT_IM_MODULE=fcitx`
  - `XMODIFIERS=@im=fcitx`
  - `SDL_IM_MODULE=fcitx`
- 启用 `i18n.inputMethod`，`type = "fcitx5"`，并开启 `fcitx5.waylandFrontend = true` 以获得 Wayland 下更好的兼容性与性能。
- 安装插件与主题包（见下文）。
- 通过 `xdg.portal` 注册 `org.freedesktop.impl.portal.Settings` 接口（由 gtk portal 实现），供 Fcitx5 检测系统深浅色。

## 引擎与中文输入方案
中文能力由 Rime 引擎提供，在 `host/base/desktop.nix` 的 `fcitx5.addons` 中声明：

- `fcitx5-rime`，并通过 `rimeDataPkgs` 注入 `rime-ice`、`rime-moegirl`、`rime-zhwiki` 数据包。
- 核心（两 DE）：`qt6Packages.fcitx5-chinese-addons`、`qt6Packages.fcitx5-configtool`、`kdePackages.fcitx5-qt`。
- Hyprland 专属（`lib.optionals (!gnome)`）：`fcitx5-gtk` 桥 + 主题包（mellow/material/catppuccin）。

拼音、五笔、注音等具体方案由 Rime 数据与用户方案决定；上述数据包提供基础词库能力。如需新增或切换方案，在 Rime 数据层配置即可（不在本仓库内直接体现）。

## 主题与候选窗定制
ClassicUI 主题与候选窗在 `host/base/desktop.nix` 的 `fcitx5.settings.addons.classicui.globalSection` 中设置（`lib.mkIf (!gnome)`，仅 Hyprland；GNOME 候选窗由 kimpanel 扩展绘制）：

- 浅色主题 `Theme = "mellow-wechat"`，深色主题 `DarkTheme = "mellow-wechat-dark"`。
- `UseDarkTheme = "True"`：让 Fcitx5 通过 XDG Settings 接口自动跟随系统深浅色（由 Noctalia 调度）。
- `"Vertical Candidate List" = "True"`：启用垂直候选列表，更适合长词条与高分屏。

安装的主题包：`fcitx5-mellow-themes`、`fcitx5-material-color`、`catppuccin-fcitx5`。

> 注意：键名含空格必须加引号（如 `"Vertical Candidate List"`）；布尔值必须大写 `True`/`False`。相关踩坑见反链 memory 卡。

## 桌面集成与崩溃自恢复
- GTK/Qt/SDL 应用均通过环境变量接入 fcitx，无需逐应用配置。
- Wayland 下启用 `waylandFrontend` 减少 X11 桥接开销。
- 在 Hyprland 下，`home/de/hyprland.nix` 为 Fcitx5 提供 systemd user service 的崩溃自恢复策略（on-failure 重启），提升长期稳定性。
- `home/theme-base.nix` 负责字体/光标与 Portal 注册，确保候选窗渲染与深浅色联动正常。

## 架构总览
下图展示从应用到 Fcitx5 再到 Rime 的数据流，以及主题与 Portal 的交互路径。

```mermaid
sequenceDiagram
participant App as "应用程序(GTK/Qt/SDL)"
participant Env as "环境变量<br/>GTK_IM_MODULE/QT_IM_MODULE/XMODIFIERS"
participant FC as "Fcitx5(含 Wayland 前端)"
participant Rime as "Rime 引擎"
participant Theme as "ClassicUI 主题"
participant Portal as "XDG Settings 接口"
App->>Env : 读取 IM 模块变量
Env-->>FC : 选择 fcitx 作为 IM 模块
App->>FC : 发送输入事件/候选请求
FC->>Rime : 解析输入并生成候选
Rime-->>FC : 返回候选列表
FC->>Theme : 绘制候选窗(浅色/深色)
Theme->>Portal : 查询当前深浅色
Portal-->>Theme : 返回主题策略
FC-->>App : 回写输入结果/候选更新
```

依赖关系：

```mermaid
graph LR
IM["Fcitx5"] --> RIME["Rime 引擎"]
IM --> THEME["ClassicUI 主题"]
THEME --> PORTAL["XDG Settings 接口"]
IM --> GTK["GTK 应用"]
IM --> QT["Qt 应用"]
IM --> SDL["SDL 应用"]
USER["Hyprland 用户服务"] --> IM
```

## 故障排查
- 输入法不显示：检查 IM 环境变量（`GTK_IM_MODULE`、`QT_IM_MODULE`、`XMODIFIERS`）是否生效；确认 Fcitx5 进程在运行，若崩溃查看 systemd user service 是否自动重启。
- 候选窗位置异常/不可见：确认 `"Vertical Candidate List"` 为 `True`（键名含空格加引号、布尔值大写）；检查 XDG Portal 的 Settings 接口可用。
- GNOME Wayland 下候选窗飞远/不跟随光标：GNOME 只实现 `text-input-v3` 无全局坐标，必须靠 kimpanel 链路。检查 fcitx5 的 kimpanel addon 未被禁用（`~/.config/fcitx5/config` 的 `[Behavior/DisabledAddons]` 不应含 kimpanel）；`host/base/desktop.nix` 已声明 `fcitx5.settings.globalOptions.Behavior.EnabledAddons = "kimpanel"` 防复发，且 GNOME kimpanel 扩展需启用。kimpanel 启用后候选窗由扩展绘制，classicui 主题（mellow-wechat）不再作用于 GNOME 会话——GNOME 下候选窗跟随 Shell 主题（本机 Material-Gnome）。
- 主题不跟随深浅色：确认 `UseDarkTheme = "True"` 且 gtk portal 已在当前桌面注册。
- 候选窗样式/透明度问题：调整 ClassicUI 的 `Theme`/`DarkTheme`，并确保字体与 DPI 设置合理。

## 配置速查
- 环境变量：`GTK_IM_MODULE`/`QT_IM_MODULE`/`XMODIFIERS`/`SDL_IM_MODULE` 指向 fcitx。
- 插件与主题：`fcitx5-gtk`、`qt6Packages.fcitx5-chinese-addons`、mellow/material/catppuccin 主题包。
- Rime 数据：`rime-ice`、`rime-moegirl`、`rime-zhwiki`。
- 候选窗：`"Vertical Candidate List" = "True"`。
- 深浅色联动：`UseDarkTheme = "True"`，配合 XDG Settings 接口。

## 相关链接
- 桌面深色模式与主题联动：[darkmode.md](./darkmode.md)
- Hyprland 桌面配置：[hyprland.md](./hyprland.md)
- 决策：垂直候选窗与布尔值大写等踩坑 → [fcitx5-vertical-candidates](../../memory/cards/fcitx5-vertical-candidates.md)
- 决策：Portal / gtk 悬空软链问题 → [portal-gtk-dangling-symlink](../../memory/cards/portal-gtk-dangling-symlink.md)
