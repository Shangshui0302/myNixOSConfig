---
title: Neovim
category: dev
tags: [nvim, editor, lsp, lazy-nvim]
updated: 2026-08-06
---

# Neovim 使用指南

> **目录**
> 1. [基本概念](#基本概念)
> 2. [基础操作](#基础操作)
> 3. [Leader 键菜单](#leader-键菜单)
> 4. [插件详解](#插件详解)
> 5. [哪些插件需要我配置？](#哪些插件需要我配置)
> 6. [常用工作流](#常用工作流)
> 7. [插件管理](#插件管理)
> 8. [故障排查](#故障排查)
> 9. [相关链接](#相关链接)

本机 Neovim 配置基于 kickstart 风格 (`~/.config/nvim/init.lua`)，由 Nix 管理，启动时自动安装插件。

## 基本概念

### CapsLock = Esc

CapsLock 已全局映射为 Esc（通过 Hyprland `kb_options: caps:escape`）。按 CapsLock 等于按 Esc，不需要 `jk` 了。

### 模式（Mode）

Neovim 是模态编辑器，有四种核心模式：

| 模式 | 进入方式 | 用途 |
|------|---------|------|
| **Normal** | `Esc` / `CapsLock` | 浏览、操作文本（默认模式） |
| **Insert** | `i` / `a` / `o` 等 | 输入文字 |
| **Visual** | `v` / `V` / `Ctrl+v` | 选中文本 |
| **Command** | `;` 或 `:` | 执行命令 |

### Leader 键

本配置的 Leader 键是 **Space**。按下 Space 后弹窗提示可用快捷键（which-key）。

---

## 基础操作

> 按键后的英文提示词帮助记忆：`d`(elete) = 删除，`y`(ank) = 复制，`p`(aste) = 粘贴，`i`(nsert) = 插入，`a`(ppend) = 追加，`o`(pen) = 新行，`w`(ord) = 单词，`b`(ack) = 回退，`u`(ndo) = 撤销

### 移动光标

| 按键 | 功能 |
|------|------|
| `h` / `j` / `k` / `l` | 左 / 下 / 上 / 右 |
| `w` / `b` | 下一个 / 上一个单词开头 (w=word, b=back) |
| `0` / `$` | 行首 / 行尾 |
| `gg` / `G` | 文件开头 / 末尾 (g=go) |
| `Ctrl+d` / `Ctrl+u` | 向下 / 上翻半页 (d=down, u=up) |

### 编辑

| 按键 | 助记 | 功能 |
|------|------|------|
| `i` | insert | 光标前进入插入模式 |
| `a` | append | 光标后进入插入模式 |
| `o` | open | 下方新建一行，进入插入模式 |
| `u` / `Ctrl+r` | undo / redo | 撤销 / 重做 |
| `dd` | delete | 删除当前行 |
| `yy` | yank | 复制当前行 |
| `p` | paste | 粘贴 |
| `x` | cut | 删除光标所在字符 |

### 窗口操作

| 按键 | 助记 | 功能 |
|------|------|------|
| `Ctrl+h` | left | 跳到左边窗口 |
| `Ctrl+j` | down | 跳到下面窗口 |
| `Ctrl+k` | up | 跳到上面窗口 |
| `Ctrl+l` | right | 跳到右边窗口 |

### 代码注释

| 按键 | 功能 |
|------|------|
| `gcc` | 注释 / 取消注释当前行 |
| `gc` + 动作 | 注释 / 取消注释目标区域（如 `gcip` 注释段落） |

### 自定义快捷键

| 按键 | 功能 |
|------|------|
| `;` | 进入命令行模式（等同于 `:`，少按一个 Shift） |
| `Esc` / `CapsLock` | 清除搜索高亮 |

---

## Leader 键菜单

> `<leader>` = Space 键。按下 Space 后 which-key 弹窗，**不需要背**，翻菜单就能找到。

### 文件与搜索 (f)

| 按键 | 功能 |
|------|------|
| `<leader>ff` | 按文件名搜索 |
| `<leader>fg` | 全文搜索 (grep) |
| `<leader>fw` | 搜索光标下的词 |
| `<leader>fb` | 已打开文件列表 |
| `<leader>fr` | 最近打开的文件 |
| `<leader>fh` | 搜索帮助文档 |
| `<leader>fk` | 搜索快捷键列表 |
| `<leader>fc` | 搜索命令列表 |
| `<leader>s/` | 当前文件内模糊搜索 |

### 文件树 (e)

| 按键 | 功能 |
|------|------|
| `<leader>e` / `Ctrl+n` | 切换侧边文件树 |

### 缓冲区 (b)

| 按键 | 功能 |
|------|------|
| `<leader>bd` | 关闭当前文件 |
| `<leader>bn` | 下一个文件 |
| `<leader>bp` | 上一个文件 |
| `<leader><leader>` | 切回上一个文件（最常用） |

### 窗口 (w)

| 按键 | 功能 |
|------|------|
| `Ctrl+h/j/k/l` | 跳到左右下上窗口 |
| `<leader>wv` | 竖直拆分 |
| `<leader>ws` | 水平拆分 |
| `<leader>wq` | 关闭当前窗口 |

### 代码 LSP

LSP 在打开 `.html` / `.css` / `.lua` 等文件时自动激活。

| 按键 | 功能 |
|------|------|
| `gd` | 跳转到定义 |
| `gr` | 查找所有引用 |
| `K` | 查看符号文档 |
| `<leader>rn` | 重命名符号 |
| `<leader>ca` | 代码操作（快速修复） |

### 补全

输入时自动弹出。

| 按键 | 功能 |
|------|------|
| `Tab` / `Shift+Tab` | 下 / 上移动 |
| `Ctrl+Space` | 手动触发 |
| `Enter` | 确认 |
| `Ctrl+e` | 关闭 |

### Git (hunk)

| 按键 | 功能 |
|------|------|
| `]c` / `[c` | 下 / 上一个改动块 |
| `<leader>hs` | 暂存改动 |
| `<leader>hr` | 撤销改动 |
| `<leader>hp` | 预览改动 |

### 开关 (t)

| 按键 | 功能 |
|------|------|
| `<leader>tn` | 行号开关 |
| `<leader>tr` | 相对行号开关 |
| `<leader>tw` | 换行开关 |
| `<leader>tC` | 主题浏览器（实时预览） |

### 其他

| 按键 | 功能 |
|------|------|
| `<leader>fs` | 保存文件 |
| `<leader>qq` | 退出 nvim |

---

## 插件详解

> 大部分插件开箱即用。标 ⚙️ 的需要你手动配置。

### 主题（4 个）

| 主题 | 变体 | 风格 |
|------|------|------|
| tokyonight | night, storm, day, moon | 蓝紫冷色 |
| catppuccin | mocha, latte, frappe, macchiato | 暖灰底 |
| rose-pine | moon, dawn, main | 玫瑰暖色 |
| kanagawa | wave, dragon, lotus | 浮世绘复古 |

`<leader>tC` 打开 telescope 主题浏览器，**上下移动实时预览**，回车选中。

### nvim-treesitter — 语法高亮

精准的代码高亮和智能缩进。预装解析器覆盖 `lua`、`vim`、`html`、`css`、`markdown`、`bash`、`nix`，打开新类型时自动安装。

### nvim-tree.lua — 文件树 `⚙️`

侧边栏文件浏览器，`<leader>e` 或 `Ctrl+n` 开关。

| 操作 | 按键 |
|------|------|
| 打开文件/文件夹 | `Enter` |
| 新建文件 | `a` (add) |
| 删除 | `d` (delete) |
| 重命名 | `r` (rename) |

### telescope.nvim — 模糊搜索 `⚙️`

最常用的查找工具，模糊匹配文件名和内容。在 telescope 窗口内：`Ctrl+j/k` 移动，`Enter` 打开，`Esc` 退出。

已映射的搜索入口：

| 按键 | 搜索内容 |
|------|---------|
| `<leader>ff` | 文件名 |
| `<leader>fg` | 全文 |
| `<leader>fw` | 光标下单词 |
| `<leader>fb` | 已打开文件 |
| `<leader>fr` | 最近文件 |
| `<leader>fh` | 帮助文档 |
| `<leader>fk` | 快捷键 |
| `<leader>fc` | 命令 |
| `<leader>s/` | 当前文件内 |

### which-key.nvim — 快捷键提示

按 `<leader>` 后自动弹窗显示可用快捷键，无需记忆。

### conform.nvim — 格式化 `⚙️`

保存时自动格式化。当前配置：`.lua` → `stylua`，其他文件通过 LSP 回退。

**你要改的**：给新语言加 formatter，在 `formatters_by_ft` 里加。比如要格式化 Python：

```lua
formatters_by_ft = {
  lua = { "stylua" },
  python = { "isort", "black" },
},
```

### 补全系统（nvim-cmp + 依赖）

| 插件 | 作用 | 需要配吗 |
|------|------|---------|
| nvim-cmp | 补全引擎核心 | 否 |
| cmp-nvim-lsp | LSP 补全（函数名、字段） | 否 |
| cmp-buffer | 文件中出现过的词 | 否 |
| cmp-async-path | 文件路径补全 | 否 |
| cmp-nvim-lua | Neovim Lua API | 否 |
| LuaSnip | 代码片段引擎 | 否 |
| friendly-snippets | 预置片段（if/for/fun 等） | 否 |

### mason.nvim — LSP 安装器 `⚙️`

`:Mason` 打开面板，`i` 安装，`X` 卸载。你目前装了 `html`、`cssls`。需要新语言（如 Python 的 `pyright`）时自己装。

LSP 服务器配置在 init.lua 的 `vim.lsp.config()` 部分，装完后要添加对应的 `vim.lsp.config` + `vim.lsp.enable`。

### gitsigns.nvim — Git 标记 `⚙️`

行号左侧显示 Git 状态：`┃` 绿=新增，`~` 橙=修改，`▸` 红=删除。

| 按键 | 功能 |
|------|------|
| `]c` | 跳到下一个 Git 改动块 |
| `[c` | 跳到上一个 Git 改动块 |
| `<leader>hs` | 暂存当前改动块 (stage hunk) |
| `<leader>hr` | 撤销当前改动块 (reset hunk) |
| `<leader>hp` | 预览当前改动块 (preview hunk) |

### nvim-autopairs — 括号配对

输入 `(` `{` `[` `"` 自动补后半。开箱即用。

### indent-blankline.nvim — 缩进线

代码块竖线对齐，帮助看清嵌套。开箱即用。

### markview.nvim — Markdown 预览

打开 `.md` 时自动渲染排版，标题/链接/代码块有独立配色。开箱即用。

### ts-comments.nvim — 代码注释

Treesitter 驱动的注释插件。`gcc` 注释/取消当前行，`gc` + 文本对象注释区域。开箱即用。

---
## 哪些插件需要我配置？

| 优先级 | 插件 | 什么时候要动 |
|--------|------|-------------|
| 必配 | `conform.nvim` | 每增加一个需要格式化的语言 |
| 必配 | LSP (`vim.lsp.config`) | 每增加一个需要代码提示的语言 |
| 选配 | `telescope.nvim` | 想加更多搜索快捷键时 |
| 选配 | `nvim-tree.lua` | 想改文件树行为时 |
| 永不 | 其余 10 个插件 | 默认配置够用 |

---

## 常用工作流

### 编辑 Nix 配置

```
<leader>e    → 打开文件树，在仓库里浏览
<leader>ff   → 搜索 nix 文件名
<leader>fg   → 全文搜索配置项关键词
gcc          → 注释/取消注释配置行
]c / [c      → 浏览 Git 改动
<leader>hs   → 暂存当前改动
# 保存时 stylua 自动格式化 .lua 文件
```

### 阅读 Markdown

```
<leader>ff   → 打开 .md 文件，markview 自动渲染
<leader>tC   → 打开主题浏览器，挑配色
;q           → 退出
```

### 写代码

```
# LSP 自动激活
gd           → 跳到定义
<leader>rn   → 重命名
# 补全自动弹出，Tab 选择确认
```

---

## 插件管理

| 命令 | 功能 |
|------|------|
| `:Lazy` | 打开插件面板，查看状态/更新 |
| `:Lazy sync` | 安装/更新/清理插件 |
| `:Lazy clean` | 删除不再使用的插件 |
| `:Mason` | 管理 LSP 语言服务器 |

---

## 故障排查

### 补全不工作

`:LspInfo` — 检查 LSP 是否运行。未启动则 `:Mason` 确认服务器已安装。

### 插件报错

`:Lazy` — 红色标记的插件需要 `:Lazy sync`。

### 启动报错

```bash
nvim --headless -c 'qa!' 2>&1 | head -20
```

### 配置被覆盖

Nix rebuild 重置 `~/.config/nvim/init.lua`。永久修改改 `~/myNixOSConfig/home/nvim/init.lua` 然后 rebuild。

## 相关链接

- [Yazi 文件管理器](yazi.md) — smart-enter 用 Neovim 打开文本文件
- [Shell 环境](../desktop/shell.md) — 终端编辑器的 alias 环境
- [wiki 首页](../README.md)
