# Neovim 使用指南

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

## 快捷键总览

> `<leader>` = Space 键。按下 `<leader>` 后 which-key 会自动弹窗提示。

### 文件与搜索

| 按键 | 插件 | 功能 |
|------|------|------|
| `<leader>e` | nvim-tree | 切换侧边文件树 (e=explore) |
| `Ctrl+n` | nvim-tree | 同上（备选） |
| `<leader>ff` | telescope | 按文件名搜索 (f=find, f=file) |
| `<leader>fg` | telescope | 全文搜索 (f=find, g=grep) |
| `<leader>fb` | telescope | 已打开文件列表 (f=find, b=buffer) |
| `<leader>fh` | telescope | 搜索帮助文档 (f=find, h=help) |

### 代码（LSP）

LSP 在打开 `.html` / `.css` / `.lua` 等文件时自动激活。

| 按键 | 助记 | 功能 |
|------|------|------|
| `gd` | go to definition | 跳转到定义 |
| `gr` | go to references | 查找所有引用 |
| `K` | — | 查看符号文档（悬浮窗） |
| `<leader>rn` | rename | 重命名符号 |
| `<leader>ca` | code action | 代码操作（快速修复） |

### 补全

输入代码时自动弹出补全菜单。

| 按键 | 功能 |
|------|------|
| `Tab` / `Shift+Tab` | 补全列表中下 / 上移动 |
| `Ctrl+Space` | 手动触发补全 |
| `Enter` | 确认选择 |
| `Ctrl+e` | 关闭补全菜单 |

### 主题

| 按键 | 功能 |
|------|------|
| `<leader>tc` | 切换配色 (t=theme, c=cycle)：night → storm → day → moon 循环 |

内置四种 tokyonight 变体：`night`(暗)、`storm`(风暴)、`day`(亮)、`moon`(月)。

---

## 插件详解

> 大部分插件开箱即用。标 ⚙️ 的需要你手动配置。

### tokyonight.nvim — 主题

深色配色方案，`<leader>tc` 在四种变体间循环切换，立即生效。

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

最常用的查找工具，模糊匹配文件名和内容。

在 telescope 窗口内：`Ctrl+j/k` 移动光标，`Enter` 打开，`Esc` 退出。

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

## 插件 UI 能汉化吗？

不能。这些插件界面（mason、telescope、which-key 等）都是英文硬编码的，不支持 i18n。好消息是都是高频短词（install、delete、search、find），用几次就记住了。

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
<leader>tc   → 调到喜欢的配色
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
