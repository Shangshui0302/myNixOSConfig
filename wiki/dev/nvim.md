---
title: Neovim
category: dev
tags: [nvim, editor, lsp, snacks, lualine, telescope]
updated: 2026-09-08
---

# Neovim 使用指南

> **目录**
> 1. [基本概念](#基本概念)
> 2. [启动导航页](#启动导航页)
> 3. [基础操作](#基础操作)
> 4. [Leader 键菜单](#leader-键菜单)
> 5. [插件详解](#插件详解)
> 6. [哪些插件需要我配置？](#哪些插件需要我配置)
> 7. [常用工作流](#常用工作流)
> 8. [插件管理](#插件管理)
> 9. [故障排查](#故障排查)
> 10. [相关链接](#相关链接)

本机 Neovim 配置基于 kickstart 风格 (`~/.config/nvim/init.lua`)，由 Home Manager 管理。插件随 Nix 配置安装，启动时不会联网克隆或更新插件。

## 启动导航页

直接运行 `nvim`（不带文件参数）会进入 Snacks dashboard：上方运行 `chafa`（最大 `64x28`，保持原图比例）显示壁纸色块，下方提供按黄金分割比例收窄并居中的常用入口菜单；菜单使用统一行距和粗体显示并隐藏光标块。启动页不显示额外标题或标语，也不会显示终端进程退出提示。打开具体文件时会直接进入编辑器，不显示启动页。

| 按键 | 入口 | 作用 |
|------|------|------|
| `f` | Find file | 用 Telescope 查找文件 |
| `e` | Browse files | 打开 nvim-tree 文件浏览器 |
| `n` | New file | 创建空缓冲区并进入插入模式 |
| `g` | Live grep | 在项目中全文搜索 |
| `r` | Recent files | 打开最近使用的文件 |
| `q` | Quit | 退出 Neovim |

启动页的图片命令和按钮由 `home/dev/nvim/init.lua` 配置，`chafa` 由 `home/dev/nvim.nix` 提供；修改后需要通过 Nix 应用配置才会出现在 `~/.config/nvim/init.lua`。

启动页和状态栏的强调色由 Matugen 生成的 `~/.cache/matugen/nvim-colors.lua` 提供：`primary` 用于图标和 Normal 状态，`secondary` 用于快捷键和 Insert 状态，`tertiary` 用于 Visual 状态，`error` 用于 Replace 状态。Tokyonight 仍负责语法高亮，透明背景继续交给 Foot。壁纸或深浅模式变化后，重启 Neovim，或在已打开的实例执行 `:MatugenReload` 读取当前调色板。

### 与 Foot 的透明毛玻璃

Neovim 本身只负责绘制透明背景，实际的半透明和模糊由 Foot 与窗口管理器提供：

- 当前主题默认使用 `tokyonight-night`，编辑区、浮动窗口、文件树、Telescope 和 Snacks dashboard 的背景设为透明。
- Foot 的暗色配置使用 `alpha = 0.8` 和 `blur = yes`，因此通过 `foot -e nvim` 启动时会沿用终端的毛玻璃背景。
- 透明效果依赖 Foot 和 compositor；从不支持透明/模糊的终端启动时，Neovim 只会显示终端的普通背景。

如果切换主题，`ColorScheme` 自动命令会再次应用透明背景；仍有不透明区域时先确认实际运行在 Foot 中。

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

`<leader>tC` 打开 telescope 主题浏览器，**上下移动实时预览**，回车选中。主题背景已设为透明，默认的 `tokyonight-night` 会显示 Foot 的毛玻璃背景。

### snacks.nvim — 启动导航页

Snacks dashboard 只在无文件参数启动时显示，上方用 `chafa` 将壁纸转换为彩色色块，下方提供按黄金分割比例收窄并居中的查找文件、浏览文件、新建文件、全文搜索、最近文件和退出六个入口；不显示额外标语。入口和操作见[启动导航页](#启动导航页)。

### lualine.nvim — Starship 风格状态栏

底部状态栏复用 Starship 的布局、配色语义和 Nerd Font 风格，但只保留 Neovim 能可靠判断的编辑上下文：模式、当前目录、Git 分支/改动、诊断、文件名、文件类型、Nix shell、时间和光标位置。颜色优先读取 Matugen 的 `nvim-colors.lua`，文件不存在时回退到固定 Starship 配色。OS、用户名/主机名、Python/Node/Rust/Docker 环境、命令耗时、电池和 shell 提示符仍留在 Starship 中。

### nvim-treesitter — 语法高亮

精准的代码高亮和智能缩进。预装解析器覆盖 `lua`、`vim`、`vimdoc`、`html`、`css`、`markdown`、`bash`、`nix`；解析器列表由 Nix 管理，增加语言时修改 `home/dev/nvim.nix`。

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
| 按需 | `snacks.nvim` | 想修改启动页图片、布局或入口时 |
| 按需 | `lualine.nvim` | 想修改底部状态栏组件或配色时 |
| 按需 | `home/dev/nvim.nix` | 新增、删除或固定插件及 Treesitter 解析器时 |

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

插件由 Home Manager 的 `programs.neovim.plugins` 管理，不使用 `lazy.nvim`，启动时也不会联网安装或更新插件。

| 位置/命令 | 功能 |
|------|------|
| `home/dev/nvim.nix` | 声明插件、Treesitter 解析器和额外工具 |
| `home/dev/nvim/init.lua` | 配置插件行为、启动页、快捷键和主题 |
| `:Mason` | 管理 LSP 语言服务器（不负责 Neovim 插件） |

修改插件声明或 Lua 配置后，在仓库目录先做结构检查：

```bash
nix-instantiate --parse home/dev/nvim.nix
nixos-rebuild dry-build --flake .
```

确认无误后由用户手动应用：

```bash
sudo nixos-rebuild switch --flake .
```

---

## 故障排查

### 补全不工作

`:LspInfo` — 检查 LSP 是否运行。未启动则 `:Mason` 确认服务器已安装。

### 插件报错

先运行上面的 `nixos-rebuild dry-build`，确认插件已在 `home/dev/nvim.nix` 声明并已应用对应 generation；不要使用已经移除的 `:Lazy sync`。

### 启动报错

```bash
nvim --headless -c 'qa!' 2>&1 | head -20
```

### 配置被覆盖

Nix rebuild 会重新生成 `~/.config/nvim/init.lua`。永久修改应编辑 `~/myNixOSConfig/home/dev/nvim/init.lua`，然后按[插件管理](#插件管理)中的流程检查并应用。

## 相关链接

- [Yazi 文件管理器](yazi.md) — smart-enter 用 Neovim 打开文本文件
- [Shell 环境](../desktop/shell.md) — 终端编辑器的 alias 环境
- [wiki 首页](../README.md)
