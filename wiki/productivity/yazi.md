---
title: Yazi 文件管理器
category: 生产力
tags: [yazi, file-manager, tui, ffmpeg, plugins]
updated: 2026-09-08
---

# Yazi 文件管理器

Yazi 是终端文件管理器，命令别名 `y`。配置了自定义主题、10 个插件和自定义按键映射。

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
| `Ctrl + N` | 拖动当前文件 | dragon-drop |
| `C` | 压缩当前文件 | ouch 插件 |
| `F` | 智能过滤 | smart-filter 插件 |
| `g` `c` | 查看 Git 文件变更 | vcs-files 插件 |
| `T` | 显示/隐藏预览面板 | toggle-pane 插件 |

**智能进入行为：**
- 目录 → 进入目录
- 文本/代码文件 → 用 Neovim 打开
- 媒体文件 → 用 mpv 播放
- 其他 → 用系统默认程序打开

## 默认打开规则

以下文件类型直接用 Neovim 打开（不走默认程序）：

`.md` `.nix` `.txt` `.rs` `.py` `.js` `.ts` `.json` `.toml` `.yaml` `.lua`

音频和视频文件由 `mpv` 打开；编辑器和播放器使用当前文件路径参数，播放器以孤儿进程运行，避免阻塞 Yazi。

## 插件一览

| 插件 | 功能 |
|------|------|
| `smart-enter` | 智能进入（目录/文件/媒体自动选择打开方式） |
| `jump-to-char` | 按 `f` + 字符快速跳转到文件名 |
| `starship` | Starship 提示符集成 |
| `ouch` | 在 Yazi 中压缩归档 |
| `smart-filter` | 快速过滤当前目录 |
| `git` | Git 状态与文件信息 |
| `vcs-files` | 查看 Git 变更文件 |
| `toggle-pane` | 切换预览面板 |
| `piper` | 管道式预览扩展 |
| `rich-preview` | Markdown、RST、JSON、CSV、IPYNB 等富预览 |

## 主题

活动主题：**matugen-runtime**（暗色），基于当前壁纸的 Matugen Material 3 色板。

Yazi 与 btop 一样保持深色底，因为 Foot 终端背景固定为深色；目录、重点、选中、边框、文件类型和错误颜色会随壁纸重点色更新。运行时 flavor 是用户可写文件，不会覆盖同目录下的 `myargonaut` 或 `noctalia`。

`theme-apply` 将产物缓存到 `~/.cache/wallpaper-colors/cache/<key>/dark/yazi/flavor.toml`，再复制到 `~/.config/yazi/flavors/matugen-runtime.yazi/flavor.toml`。壁纸变化时重新取色，普通 Darkman 深浅切换复用缓存；当前运行实例若未热重载，重新打开 Yazi 即可读取新颜色。

### 切换主题

静态回退主题仍在 `/home/lishangshui/myNixOSConfig/home/productivity/yazi.nix` 的 `myargonaut` 配置中；如需修改 Matugen 的颜色映射，编辑 `home/theme/matugen/yazi-flavor.toml.tpl` 后再由用户手动 rebuild。

## 预览功能

- **文本文件**：语法高亮预览
- **图片**：缩略图预览（ImageMagick）
- **视频**：缩略图预览（ffmpeg）
- **压缩包**：通过 `ouch` 预览归档内容
- **富文本**：通过 `rich-preview` 预览 Markdown、RST、JSON、CSV 和 IPYNB
- **Git 文件**：通过 `git`/`vcs-files` 显示版本控制状态
- **预览尺寸限制**：1000×1000 像素
- **面板比例**：`[2, 3, 4]`（父目录：当前目录：预览）

视频预览调用 `ffmpeg` 命令行工具；FFmpeg 作为视频工具声明在 `home/productivity/graphics.nix`，Yazi 只复用其可执行文件。

## 故障排查

- **视频没有缩略图**：确认 `command -v ffmpeg` 能找到可执行文件；修改包声明后由用户手动 rebuild。
- **富预览不可用**：确认 `rich-preview` 及其 `rich-cli` 依赖已进入 Home Manager 环境。
- **拖动文件没有反应**：确认 `command -v dragon-drop` 可用，并在文件上悬停后按 `Ctrl + N`。

## 文件图标

文件按类型显示不同颜色的 Nerd Font 图标：

| 类型 | 图标颜色（Matugen 角色） | 示例 |
|------|----------|------|
| 目录（悬停） | `primary` | `` |
| 目录（普通） | `secondary` | `` |
| 可执行文件 | `primary` | `` |
| 图片 | `tertiary` | `󰉏` |
| 视频/音频 | `tertiary_container` | `` / `` |
| 压缩包 | `secondary_container` | `󰛫` |
| Nix 文件 | `secondary` | `󰋗` |
| Python | `tertiary` | `` |
| Rust | `error` | `` |
| JS/TS | `tertiary` / `secondary` | `` / `` |

## 设置概览

| 设置 | 值 |
|------|-----|
| 显示隐藏文件 | 是 |
| 排序方式 | 字母序，目录优先 |
| 显示符号链接 | 是 |
| 插件 | 10 个（含预览、Git、压缩和面板控制） |
| Shell 别名 | `y`（fish 集成） |

## 相关链接

- [Neovim](../dev/nvim.md) — smart-enter 用 Neovim 打开文本文件
- [Shell 环境](../desktop/shell.md) — `y` 别名的 fish 集成
- [wiki 首页](../README.md)
