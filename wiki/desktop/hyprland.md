---
title: Hyprland
category: desktop
tags: [wm, wayland, hyprland, scrolling-layout]
updated: 2026-08-10
---

# Hyprland 使用指南

> **目录**
> 1. [基本概念](#基本概念)
> 2. [快捷键](#快捷键)
> 3. [触控板手势](#触控板手势)
> 4. [启动时自动运行](#启动时自动运行)
> 5. [常用工作流](#常用工作流)
> 6. [主题](#主题)
> 7. [故障排查](#故障排查)
> 8. [相关链接](#相关链接)

本机 Hyprland 配置基于 Lua (`~/.config/hypr/hyprland.lua`)，使用 **scrolling layout**（滚动列布局）。

## 基本概念

### 滚动布局 (Scrolling Layout)

窗口按列排列，新窗口自动成为主列（master）。列数随窗口增多自动扩展，工作区内容超出屏幕时可以左右滚动。

- 列宽分布：33% → 50% → 67% → 81% → 96%（随窗口数递增）
- 焦点跟随滚动
- 全屏应用独占一列

### 工作区

共 10 个工作区（1–10），外加一个特殊工作区（scratchpad）。

---

## 快捷键

> `Super` = Win/Command 键

### 启动应用

| 按键 | 功能 |
|------|------|
| `Super + Q` | 终端 (foot) |
| `Super + E` | 文件管理器 (Nemo) |
| `Super + Space` | 应用启动器 (Noctalia) |
| `Super + K` | 控制中心 (Noctalia) |
| `Super + ,` | 设置面板 (Noctalia) |
| `Super + Tab` | 工作区总览 (Noctalia) |

### 截图

| 按键 | 功能 |
|------|------|
| `Print` | 全屏截图（自动保存 + 复制到剪贴板） |
| `Shift + Print` | 区域截图（Swappy 编辑后保存 + 复制） |

截图保存在 `~/Pictures/Screenshots/YYYY-MM/` 目录下。

### 窗口管理

| 按键 | 功能 |
|------|------|
| `Super + W` | 关闭窗口 |
| `Super + V` | 浮动 / 平铺切换 |
| `Super + F` | 全屏切换 |
| `Super + P` | 伪平铺（保持窗口位置但参与布局） |

### 焦点与工作区

| 按键 | 功能 |
|------|------|
| `Super + ←/→/↑/↓` | 切换焦点 |
| `Super + 1–0` | 切换到工作区 1–10 |
| `Super + S` | 切换特殊工作区（scratchpad） |
| `Super + Shift + S` | 移动窗口到特殊工作区 |

### 窗口移动 / 缩放 / 交换

| 按键 | 功能 |
|------|------|
| `Super + Ctrl + ←/→/↑/↓` | 调整窗口大小 |
| `Super + Ctrl + 0–9` | 调整窗口大小为 10% 增量预设（1920×1200 逻辑像素） |
| `Super + Shift + ←/→/↑/↓` | 移动窗口 |
| `Super + Alt + ←/→/↑/↓` | 交换窗口位置 |
| `Super + Shift + 1–0` | 窗口移到工作区 1–10 |

### 退出

| 按键 | 功能 |
|------|------|
| `Super + Shift + M` | 退出 Hyprland |

### 媒体 & 亮度

| 按键 | 功能 |
|------|------|
| 音量 +/- | 调整 2% |
| 静音 | 切换静音 |
| 麦克风静音 | 切换麦克风 |
| 亮度 +/- | 调整亮度 |

### 鼠标操作

| 操作 | 功能 |
|------|------|
| `Super + 滚轮` | 切换工作区 |
| `Super + 左键拖拽` | 拖动窗口 |
| `Super + 右键拖拽` | 调整窗口大小 |

---

## 触控板手势

| 手势 | 功能 |
|------|------|
| 三指上下滑动 | 切换工作区 |
| 三指左右滑动 | 平滑滚动列 |

---

## 启动时自动运行

1. **fcitx5** — 输入法
2. **Noctalia Shell** — 顶栏/侧边栏面板
3. **HVE Watchdog** — Noctalia 主题热加载守护进程

---

## 常用工作流

### 打开应用 -> 排列窗口

```
Super + Space   # 启动器搜索应用
Super + Shift + ←/→  # 调整窗口位置
Super + Ctrl + ←/→   # 调整窗口大小
```

### 多工作区管理

```
Super + 2       # 跳到工作区 2
Super + Shift + 3  # 把当前窗口移到工作区 3
Super + 鼠标滚轮   # 快速浏览工作区
```

### 小窗 / 浮动

```
Super + V       # 切换浮动（计算器、弹窗等）
Super + S       # 临时收纳到 scratchpad
Super + S       # 再按一次唤出
```

### 截图工作流

```
Print           # 全屏截图，自动存文件 + 进剪贴板
Shift + Print   # 区域截图 → Swappy 标注 → 存文件 + 剪贴板
```

---

## 主题

Noctalia 管理所有配色，主题切换后 Hyprland 边框颜色自动跟随。

当前主题：**yamadaryou**

---

## 故障排查

```
# 验证配置文件语法
hyprland --verify-config

# 查看 Hyprland 日志
cat /tmp/hypr/$(ls -t /tmp/hypr/ | head -1)/hyprland.log

# 重新加载配置（不重启）
hyprctl reload
```

### 亮度调到最高反而变黑

AMD 核显（Radeon 780M）内核 6.15+ 的 custom brightness curve 在顶端溢出、100% 亮度变全黑。已在 `host/boot.nix` 用内核参数 `amdgpu.dcdebugmask=0x40000` 禁用该曲线修复（需 reboot。为何不升内核见 `memory/cards/mechrevo-amd-backlight-curve.md`）。若重现，验证：

```
cat /sys/module/amdgpu/parameters/dcdebugmask   # 应为 262144
```

## 相关链接

- [Noctalia](noctalia.md) — 顶栏/控制中心/应用启动器，快捷键与 Hyprland 绑定
- [Shell 环境](shell.md) — `Super + Q` 启动的 foot 终端配置
- [深色模式架构](darkmode.md) — Hyprland 边框颜色跟随 Noctalia 主题
- [Memory: AMD 背光曲线溢出](../../memory/cards/mechrevo-amd-backlight-curve.md) — 100% 亮度变黑的内核参数修复
- [Memory: Hyprland 模糊 / AMD 780M](../../memory/cards/hyprland-056-blur-amd.md) — 模糊在 AMD 核显失效的处理
- [wiki 首页](../README.md)
