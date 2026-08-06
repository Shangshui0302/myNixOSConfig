---
name: wiki-maintainer
description: >
  创建和维护项目知识库（wiki/、memory/、README.md、CLAUDE.md）。当用户提到"写文档"、"更新文档"、
  "文档过时了"、"补充文档"、"完善文档"、"文档化"、"documentation"、"docs"、"wiki"、"memory"、
  "决策卡"、新增组件后需要记录配置、修改 nix 配置后需要同步 wiki/memory、或者任何涉及项目知识库的
  创建/更新/审查时，必须使用此 skill。也适用于审查 wiki 是否与 nix 配置一致、整理 wiki 结构、添加
  使用指南、补写决策卡。简而言之，任何与项目知识库（wiki + memory）相关的操作都触发此 skill。
---

# Wiki 与 Memory 维护

此 skill 用于在 NixOS 配置仓库 (`~/myNixOSConfig`) 中创建和维护知识库。

## 知识库结构

知识库分两层，职责严格区分：

```
myNixOSConfig/
├── README.md                  # 项目总览、目录结构、重建命令、新机部署
├── CLAUDE.md                  # LLM 上下文：硬件/系统信息、目录结构、服务列表、注意事项
├── wiki/                      # 操作手册 — 回答「怎么用」，含故障排查
│   ├── README.md              # wiki 导航首页：组件索引 + 分类
│   ├── hyprland.md / noctalia.md / shell.md / mihomo.md / litellm.md
│   ├── nvim.md / yazi.md / distrobox.md / darkmode.md / bottles-offline-workaround.md
│   └── constraints.md         # 约束与惯例
└── memory/                    # 决策记忆 — 回答「为什么」，AI 决策参考
    ├── INDEX.md               # 卡片索引（AI 查询入口）
    ├── _template.md           # 卡片模板
    └── cards/                 # 原子化卡片
        ├── mihomo-tun-stack.md          # decision
        ├── ai-tools-source.md           # decision
        ├── flake-unstable-strategy.md   # decision
        └── nix-search-before-manual.md  # constraint
```

**核心区分**：wiki 存「怎么用」的稳定手册；memory 存「为什么这么配」的决策卡片。故障排查归 wiki，不迁入 memory。

## Wiki 文档规范

所有 wiki 文档遵循统一风格（参照 `wiki/hyprland.md`）：

- **语言**：中文
- **格式**：Markdown，使用 `#` 层级标题
- **核心元素**：
  - 表格 — 用于快捷键、配置项、选项说明等结构化信息
  - 代码块 — 用于命令、配置示例
  - 工作流示例 — 展示常见操作流程
  - 故障排查 — 每个文档末尾包含常见问题和解决方法
- **长度**：每个文档 80-200 行，保持简洁可扫描
- **表述**：面向使用者，描述"怎么用"而非"怎么配"。nix 配置细节留在 nix 文件里，文档说清用户需要知道什么

### 文件映射

每个 nix 配置模块对应一个或多个 wiki 目标：

| Nix 配置 | Wiki 文档 | 说明 |
|----------|-----------|------|
| `home/hyprland.nix` | `wiki/hyprland.md` | Hyprland 按键、手势、工作流 |
| `home/noctalia.nix` | `wiki/noctalia.md` | Noctalia 面板、控制中心、壁纸、配色 |
| `home/shell.nix` | `wiki/shell.md` | fish/bash、别名、starship、zellij、ghostty |
| `host/litellm.nix` | `wiki/litellm.md` | AI 代理模型映射、健康检查 |
| `host/services.nix` (mihomo) | `wiki/mihomo.md` | 代理架构、WebUI、排查 |
| `home/yazi.nix` | `wiki/yazi.md` | 文件管理器按键、插件、主题 |
| 全部 host/ + home/ | `README.md` | 系统总览、目录结构、重建命令 |
| 全部 host/ + home/ + 系统 | `CLAUDE.md` | LLM 上下文、硬件信息、服务列表、注意事项 |

当新增 nix 模块时，判断是否需要创建对应的 `wiki/*.md`。判断标准：
- 组件是用户直接交互的（WM、面板、shell、编辑器等）→ 需要 wiki
- 组件配置复杂，从 nix 代码难以快速理解用法 → 需要 wiki
- 纯后台服务、用户不直接操作的 → 不需要独立 wiki

## Memory 卡片规范

### 判定是否需要决策卡

改配置时若「为什么这么改」从 nix 代码 / commit message 推不出来 → 需要一张决策卡。判断标准：配置的值带有一个非显而易见的权衡，且未来可能有人（或 AI）想改掉它。

### 三种卡片类型

| 类型 | 存什么 | 例子 |
|------|--------|------|
| `decision` | 非显而易见的配置决策（Why 代码看不出来） | mihomo 为什么 gvisor + mtu 1500 |
| `hardware` | 硬件特性、环境约束 | MS CJK 字体在 `/persist/Fonts/` |
| `constraint` | 必须遵守的硬规则 | 查包强制多路径搜索 |

**不存什么**：操作手册内容（归 wiki）、踩坑过程细节（归 wiki 故障排查）、显而易见的配置（代码能看出来）。

### 卡片格式

文件：`memory/cards/<slug>.md`，frontmatter 含 `id`（=slug）、`type`、`tags`、`date`。正文分「问题 / 决策 / Why / How to apply」，末尾 `相关:` 行交叉引用 wiki 或其他卡。

**必须同步更新 INDEX.md**：新增或修改卡片后，更新 `memory/INDEX.md` 的对应分组列表，保证索引与 `cards/` 实际文件一一对应。

## 创建新 wiki 文档

当用户新增组件或要求为已有组件写文档时：

### 1. 信息收集

- **先读 nix 配置**：完整读取对应的 nix 文件，理解所有配置项
- **再读已有文档**：至少读 `wiki/hyprland.md` 作为风格参考，读 `CLAUDE.md` 了解系统上下文
- 如果用户未指定要文档化哪个组件，先扫描 `host/` 和 `home/` 中所有 nix 文件，对比 `wiki/` 目录，找出"有配置但无文档"的组件

### 2. 确定内容结构

按以下优先级组织内容：
1. 概览 — 一句话说明这个组件是做什么的
2. 核心概念/布局 — 帮助用户建立心智模型
3. 操作方式（快捷键/鼠标/手势）— 用户最常查阅的信息
4. 配置项速查 — 重要的可配置项，用表格
5. 常用工作流 — 2-4 个典型场景的操作步骤
6. 故障排查 — 常见问题和解决命令

### 3. 编写

- 从 nix 配置中**提取**用户关心的信息，而非逐行翻译配置
- 快捷键直接用实际按键表示（`Super + Q`），不要写 nix 变量名
- 命令用代码块包裹，确保可直接复制执行
- 文档之间交叉引用（如 noctalia.md 引用 hyprland.md 的截图快捷键）

### 4. 注册

新文档写完后，检查是否需要更新：
- `wiki/README.md` — 导航首页中加入新文档的链接
- `README.md` — 目录结构部分是否需要加入新文档的说明
- `CLAUDE.md` — 目录结构中是否需要补充新组件信息

## 更新已有 wiki 文档

nix 配置变更后，对应的 wiki 可能过时。按以下流程同步：

### 触发条件

用户修改 nix 配置后，检查是否影响了 wiki 描述的"用户可见行为"：
- 按键绑定变更 → 必须更新快捷键表
- 新增/删除功能 → 必须更新对应章节
- 默认值变更 → 更新配置项表格
- 新增插件/模块 → 添加说明
- 纯内部实现重构、不影响用户使用 → 不需要更新 wiki

### 更新流程

1. 读取变更的 nix 文件（git diff 或完整读取）
2. 读取对应的 wiki 文件
3. 找出不一致的地方
4. 只修改文档中受影响的部分，保留其他内容不变
5. 如果是 CLAUDE.md 受影响，同步更新

### 决策卡联动

若本次改动涉及非显而易见的决策，**同步补一张 memory 决策卡**（见「Memory 卡片规范」）。

## 审查 wiki 过时

用户可能要求"检查 wiki 是否过时"。审查流程：

1. 对比 `wiki/` 目录和 `host/`/`home/` nix 文件，确认每个文档都有对应的配置源
2. 对于每个文档，检查：
   - 快捷键/命令是否与配置一致
   - 配置项表格中的默认值是否正确
   - 新增的功能是否已文档化
   - 已删除的功能是否从文档中移除
3. 列出所有不一致项，让用户确认后再修改
4. 同时检查 README.md 的目录结构是否与实际一致，CLAUDE.md 的服务列表是否完整
5. 检查 `memory/INDEX.md` 与 `memory/cards/` 是否一一对应，有无遗漏新卡

## README.md 维护

README.md 是项目门面，包含：
- 系统概览表
- 目录结构（含 wiki/ 和 memory/ 下文件列表）
- 重建命令
- 配置原则
- 新机部署步骤
- 首次设置说明

当以下情况发生时更新 README.md：
- 新增/删除 nix 模块文件 → 更新目录结构
- 新增 wiki 文档 → 在目录结构中添加
- 新增 memory 卡 → 目录结构一般不变，但若 memory/ 结构变化需更新
- 系统配置原则变化 → 更新配置原则部分
- 新机部署流程变化 → 更新部署步骤

## CLAUDE.md 维护

CLAUDE.md 是给 LLM 的上下文，需要保持精确。包含：
- 硬件信息（通常不变）
- 系统详情（hostname、用户、服务等）
- 目录结构（与 README.md 同步）
- 已启用服务列表
- LiteLLM 模型映射表
- Nix 配置参数
- 注意事项（硬规则，含「决策记忆」规则）

当以下情况发生时更新 CLAUDE.md：
- 新增/删除服务 → 更新服务列表
- 模型映射变更 → 更新 LiteLLM 表格
- 新增/删除 nix 模块 → 更新目录结构
- 配置规则/注意事项变化 → 更新对应部分
- 硬件变更 → 更新硬件信息

修改 CLAUDE.md 时：
- 保持信息精确，不要添加推测性内容
- 目录结构与 README.md 保持同步
- 注意事项使用强制语气（"必须"、"禁止"），因为 LLM 需要明确边界

## 知识库质量标准

每个 wiki 文档应该让读者能回答以下问题：
- 这是什么？
- 怎么打开/启动它？
- 常用操作有哪些？（快捷键、命令）
- 出问题了怎么办？（故障排查）
- 在哪儿能找到更多信息？（交叉引用）

每张 memory 卡应该让读者能回答：
- 当时遇到了什么问题？
- 做了什么决策？
- 为什么这么决策（Why）？
- 后续怎么遵守（How to apply）？
