# Neovim 使用指南

本机 Neovim 配置基于 kickstart 风格 (`~/.config/nvim/init.lua`)，由 Nix 管理，启动时自动安装插件。

## 基本概念

### 模式（Mode）

Neovim 是模态编辑器，有四种核心模式：

| 模式 | 进入方式 | 用途 |
|------|---------|------|
| **Normal** | `Esc` 或 `jk` | 浏览、操作文本（默认模式） |
| **Insert** | `i` / `a` / `o` 等 | 输入文字 |
| **Visual** | `v` / `V` / `Ctrl+v` | 选中文本 |
| **Command** | `;` 或 `:` | 执行命令 |

### Leader 键

本配置的 Leader 键是 **Space**。按一下 Space 后会有弹窗提示后续按键（which-key）。

---

## 基础操作

### 移动光标

| 按键 | 功能 |
|------|------|
| `h` / `j` / `k` / `l` | 左 / 下 / 上 / 右 |
| `w` / `b` | 跳到下一个/上一个单词开头 |
| `0` / `$` | 跳到行首 / 行尾 |
| `gg` / `G` | 跳到文件开头 / 末尾 |
| `Ctrl+d` / `Ctrl+u` | 向下/上翻半页 |

### 编辑

| 按键 | 功能 |
|------|------|
| `i` | 在光标前进入插入模式 |
| `a` | 在光标后进入插入模式 |
| `o` | 在下方新建一行进入插入模式 |
| `u` / `Ctrl+r` | 撤销 / 重做 |
| `dd` | 删除当前行 |
| `yy` | 复制当前行 |
| `p` | 粘贴 |
| `x` | 删除光标所在字符 |

### 自定义快捷键

| 按键 | 功能 |
|------|------|
| `jk` | 退出插入模式（回到 Normal） |
| `;` | 进入命令行模式（等同于 `:`） |
| `Esc` | 清除搜索高亮 |

---

## 插件功能速览

### 文件导航

| 按键 | 插件 | 功能 |
|------|------|------|
| `Ctrl+n` | nvim-tree | 切换侧边文件树 |
| `<leader>ff` | telescope | 搜索文件名 |
| `<leader>fg` | telescope | 全文搜索（grep） |
| `<leader>fb` | telescope | 切换已打开的文件 |
| `<leader>fh` | telescope | 搜索帮助文档 |

### 代码跳转（LSP）

打开 `.html` / `.css` / `.lua` 等文件后，LSP 自动激活：

| 按键 | 功能 |
|------|------|
| `gd` | 跳转到定义 |
| `gr` | 查找所有引用 |
| `K` | 查看符号文档（悬浮窗） |
| `<leader>rn` | 重命名符号 |
| `<leader>ca` | 代码操作（快速修复等） |

### 代码补全

输入代码时自动弹出补全菜单，补全来源包括 LSP 符号、文件中的词、路径、代码片段。

| 按键 | 功能 |
|------|------|
| `Tab` / `Shift+Tab` | 在补全列表中下/上移动 |
| `Ctrl+Space` | 手动触发补全 |
| `Enter` | 确认选择 |
| `Ctrl+e` | 关闭补全菜单 |

### 保存时自动格式化

`conform.nvim` 会在保存文件时自动格式化代码：
- `.lua` 文件：用 `stylua` 格式化
- 其他文件类型可通过 LSP 回退格式化（如有可用的 LSP formatter）

### Git 标记

`gitsigns.nvim` 在行号左侧显示 Git 状态：

| 标记 | 含义 |
|------|------|
| `┃` (绿) | 新增行 |
| `~` (橙) | 修改行 |
| `▸` (红) | 删除行 |

### Markdown 预览

打开 `.md` 文件时，`markview.nvim` 自动渲染格式——标题、链接、代码块等会以不同颜色和高亮显示，所见即所得。

---

## 各插件详解

### tokyonight.nvim — 主题

深色配色方案 `tokyonight-night`。无需操作，开机即用。

### nvim-treesitter — 语法高亮

提供精准的代码高亮和智能缩进。已预装 `lua`、`vim`、`html`、`css`、`markdown`、`bash`、`nix` 等语言的解析器，打开新文件类型时自动下载对应解析器。

### mason.nvim — LSP 安装器

管理语言服务器（language server）的安装。需要新语言支持时：

```
:Mason
```

打开 Mason 面板，按 `i` 安装服务器。常用服务器已预装：`html`、`cssls`。

### nvim-cmp — 补全引擎

提供智能补全窗口。补全来源（自动生效）：

| 来源 | 说明 |
|------|------|
| nvim_lsp | LSP 提供的函数名、字段、类型等 |
| buffer | 当前文件中出现过的词 |
| async_path | 文件系统路径 |
| nvim_lua | Neovim Lua API 函数名 |
| luasnip | 代码片段（if/then、for 等模板） |

### LuaSnip + friendly-snippets — 代码片段

提供常用代码模板。输入关键词后按 `Tab` 展开。例如：
- `fun` + `Tab` → 展开为函数模板
- `if` + `Tab` → 展开为 if 语句模板

### telescope.nvim — 模糊搜索

最常用的查找工具。支持模糊匹配文件名和内容。

```
<leader>ff    → 按文件名查找文件
<leader>fg    → 全文搜索（ripgrep）
<leader>fb    → 浏览已打开的文件列表
<leader>fh    → 搜索帮助文档
```

在 telescope 窗口内：`Ctrl+j/k` 上下移动，`Enter` 打开，`Esc` 退出。

### nvim-tree.lua — 文件树

侧边栏文件浏览器。`Ctrl+n` 开关。

| 操作 | 按键 |
|------|------|
| 打开文件夹 | `Enter` |
| 打开文件 | `Enter` |
| 新建文件 | `a` |
| 删除文件 | `d` |
| 重命名 | `r` |

### which-key.nvim — 快捷键提示

按 Leader（Space）后自动弹出可用快捷键菜单。按任意前缀键也会显示后续可用按键，免去记忆负担。

### conform.nvim — 代码格式化

保存 `.lua` 文件时自动调用 `stylua` 格式化。其他文件类型如需格式化，通过 LSP 回退。手动格式化：`<leader>fm`（未绑定，可通过 `:Conform format` 手动触发）。

### gitsigns.nvim — Git 状态标记

在行号左侧显示 Git 增/删/改状态。

- 行内操作：`:Gitsigns preview_hunk` 预览变更，`:Gitsigns reset_hunk` 撤销变更

### nvim-autopairs — 括号自动配对

输入 `(`、`{`、`[`、`"` 等符号时自动补全后半部分，进入插入模式即生效，无需额外操作。

### indent-blankline.nvim — 缩进引导线

在代码块中添加竖向缩进对齐线，帮助看清嵌套层级。始终开启，无需操作。

### markview.nvim — Markdown 实时预览

打开 `.md` 文件时自动渲染，标题以不同大小显示，链接/代码块/表格有专门配色。完全自动，无需操作。

### nvzone 系列

| 插件 | 命令 | 说明 |
|------|------|------|
| minty | `:Huefy` / `:Shades` | 颜色选择器，Hex 色值实时预览 |
| volt | — | 依赖框架，后台运行 |
| menu | — | 右键菜单框架 |

---

## 常用工作流

### 编辑 Nix 配置

```
# 1. 打开文件
<leader>ff   → 输入 nix 文件名

# 2. 搜索配置项
<leader>fg   → 输入关键词

# 3. 编辑 + 自动格式化
保存时 stylua 自动格式化 .lua 文件

# 4. 查看 Git 改动
gitsigns 在行号旁显示修改标记

# 5. 浏览器文件
Ctrl+n       → 在文件树中浏览仓库
```

### 阅读 Markdown 文档

```
# 打开 .md 文件后，markview 自动渲染排版
<leader>ff   → 输入 .md 文件名
# 阅读完成
;q           → 退出
```

### 写 HTML/CSS

```
# 打开 .html 文件后 LSP 自动激活
gd           → 跳转到 CSS 类定义
K            → 查看属性文档
# 输入时自动补全标签和属性
```

---

## 插件管理

插件管理器是 **lazy.nvim**。管理命令：

| 命令 | 功能 |
|------|------|
| `:Lazy` | 打开插件管理面板 |
| `:Lazy sync` | 同步（安装/更新/清理）插件 |
| `:Lazy update` | 更新所有插件 |
| `:Lazy clean` | 删除未使用的插件 |

插件配置位于 `~/.config/nvim/init.lua`（由 Nix 管理，源码在 `~/myNixOSConfig/home/nvim/init.lua`）。

修改后运行 `nixos-rebuild switch` 或直接编辑符号链接指向的 nix store 文件（不推荐，会被 rebuild 覆盖）。

## 故障排查

### 补全不工作

检查 LSP 是否运行：`:LspInfo`。如果 html/cssls 未启动，运行 `:Mason` 确认语言服务器已安装。

### 插件报错

运行 `:Lazy` 查看插件状态。红色标记的插件需要 `:Lazy sync` 重新安装。

### 配置文件报错

如果 nvim 启动后报 Lua 错误，检查配置文件：
```bash
nvim --headless -c 'qa!' 2>&1 | head -20
```

### 还原配置

Nix rebuild 会重置 `~/.config/nvim/init.lua` 到仓库版本，所有本地修改丢失。如需永久修改，改 `~/myNixOSConfig/home/nvim/init.lua` 然后 rebuild。
