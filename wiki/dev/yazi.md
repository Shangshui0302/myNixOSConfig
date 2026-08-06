---
title: Yazi 文件管理器
category: dev
tags: [yazi, file-manager, tui]
updated: 2026-08-06
---

# Yazi 文件管理器

Yazi 是终端文件管理器，命令别名 `y`。配置了自定义主题、9 个插件和自定义按键映射。

## 基本操作

| 按键 | 功能 |
|------|------|
| `j`/`k` 或 `↑`/`↓` | 上下移动 |
| `h`/`l` 或 `←`/`→` | 切换目录层级 |
| `l` 或 `Enter` | 智能进入（目录→进入，文件→打开） |
| `f` | 跳转到字符（快速定位文件） |
| `Space` | 选择/取消选择 |
| `v` | 选择模式 |
| `y` | 复制 (yank) |
| `x` | 剪切 |
| `p` | 粘贴 |
| `d` | 删除（移到回收站） |
| `a` | 创建文件/目录 |
| `r` | 重命名 |
| `.` | 显示/隐藏隐藏文件 |
| `~` | 回到 $HOME |
| `Esc` | 退出选择模式/取消操作 |
| `q` | 退出 Yazi |

## 自定义按键

| 按键 | 功能 | 来源 |
|------|------|------|
| `f` | 跳转到字符 | jump-to-char 插件 |
| `l` | 智能进入 | smart-enter 插件 |
| `Enter` | 智能进入 | smart-enter 插件 |

**智能进入行为：**
- 目录 → 进入目录
- 文本/代码文件 → 用 Neovim 打开
- 媒体文件 → 用 mpv 播放
- 其他 → 用系统默认程序打开

## 默认打开规则

以下文件类型直接用 Neovim 打开（不走默认程序）：

`.md` `.nix` `.txt` `.rs` `.py` `.js` `.ts` `.json` `.toml` `.yaml` `.lua`

## 插件一览

| 插件 | 功能 |
|------|------|
| `git` | Git 状态指示（修改/新增/删除标记） |
| `full-border` | 完整边框（替代半截边框） |
| `smart-enter` | 智能进入（目录/文件/媒体自动选择打开方式） |
| `jump-to-char` | 按 `f` + 字符快速跳转到文件名 |
| `wl-clipboard` | Wayland 剪贴板集成（复制/粘贴文件路径） |
| `mime-ext` | 根据文件扩展名识别 MIME 类型 |
| `yatline` | 自定义底部状态栏 |
| `yatline-githead` | 状态栏显示 Git HEAD 信息 |
| `starship` | Starship 提示符集成 |

## 主题

活动主题：**myargonaut**（暗色），基于 Argonaut 调色板的绿色主题。

可用主题（共 7 个）：

| 主题名 | 风格 |
|--------|------|
| `myargonaut` | 自定义 Argonaut 绿色调（默认） |
| `catppuccin-mocha` | Catppuccin 深色 |
| `tokyo-night` | Tokyo Night 深色 |
| `nord` | Nord 冷色调 |
| `synthwave84` | Synthwave 霓虹色 |
| `lain` | Lain 风格 |
| `kanagawa-paper` | Kanagawa 暖色 |

### 切换主题

编辑 `/home/lishangshui/myNixOSConfig/home/yazi.nix`，修改 `theme.flavor.dark` 为新主题名，然后 rebuild。

## 预览功能

- **文本文件**：语法高亮预览
- **图片**：缩略图预览（ImageMagick）
- **视频**：缩略图预览（ffmpeg）
- **预览尺寸限制**：1000×1000 像素
- **面板比例**：`[2, 3, 4]`（父目录：当前目录：预览）

## 文件图标

文件按类型显示不同颜色的 Nerd Font 图标：

| 类型 | 图标颜色 | 示例 |
|------|----------|------|
| 目录（悬停） | 绿色 | `` |
| 目录（普通） | 绿色 | `` |
| 可执行文件 | 绿色 | `` |
| 图片 | 青色 | `󰉏` |
| 视频/音频 | 黄色 | `` / `` |
| 压缩包 | 粉色 | `󰛫` |
| Nix 文件 | 亮绿 | `󰋗` |
| Python | 黄色 | `` |
| Rust | 红色 | `` |
| JS/TS | 黄色/青色 | `` / `` |

## 设置概览

| 设置 | 值 |
|------|-----|
| 显示隐藏文件 | 是 |
| 排序方式 | 字母序，目录优先 |
| 显示符号链接 | 是 |
| 选项卡宽度 | 1 |
| Shell 别名 | `y`（fish 集成） |

## 相关链接

- [Neovim](nvim.md) — smart-enter 用 Neovim 打开文本文件
- [Shell 环境](../desktop/shell.md) — `y` 别名的 fish 集成
- [wiki 首页](../README.md)
