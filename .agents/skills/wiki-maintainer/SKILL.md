---
name: wiki-maintainer
description: >
  在 ~/myNixOSConfig 中创建、导入、更新、审查或同步项目知识库（wiki/、memory/、README.md、AGENTS.md）。
  当用户提到“写/更新/审查/同步 wiki”“文档过时”“文档化组件”“补 memory”“决策卡”，或修改 Nix
  配置后需要同步项目知识时使用。流程覆盖目标根目录确认、来源反查、增量更新、决策沉淀和结果交接；
  普通一次性文档编辑不触发。
---

# Wiki 与 Memory 维护

IRON LAW: 先确定仓库根目录、当前 worktree 和来源事实，再写入；不覆盖用户内容、不伪造 Why、
不维护第二份来源映射。

此 skill 是通用 docs-first wiki workflow 在 `~/myNixOSConfig` 的 NixOS 适配层。外部 project-wiki 的
核心原则是“先识别模式、先读后写、增量同步、明确未知项和交接结果”；本仓库继续使用已有的
`wiki/_sources.yaml`、`memory/INDEX.md` 和分类目录，不引入平行的 `wiki/Sources.md`、`wiki/log.md` 或
plans 体系。

## 模式路由与上下文门禁

先在任务记录中选一个模式：

| 模式 | 适用 | 必须产出 |
| --- | --- | --- |
| `bootstrap` | wiki 入口缺失 | 只补明确缺失且不冲突的入口 |
| `create` / `update` | 新文档或用户可见行为变化 | 文档、导航、来源映射 |
| `sync` | Nix 改动先于文档或文档疑似过时 | 受影响文档的最小增量更新 |
| `record_decision` | 非显而易见 Why、硬件事实、约束 | memory 卡与 `INDEX.md` |
| `audit` | 用户要求检查一致性 | `pass`/`warn`/`fail` 清单和下一步 |

写入前必须完成：

- [ ] 确认当前根目录为 `~/myNixOSConfig`，读取 `AGENTS.md`、`README.md` 和相关现状。
- [ ] 运行 `git status --short`；保留 staged、unstaged、untracked 和用户 authored 文档。
- [ ] 明确目标文件和证据来源；目标、来源或已有文档冲突时标记 `blocked`，先询问。
- [ ] 非小型创建、广泛审查、移动、重命名、删除或 memory 写入先展示范围并等待确认。

“继续/恢复”只做定位：先读当前分支、worktree、计划/文档状态，再询问是创建计划、修订计划还是开始实施。

## 知识库结构

知识库分两层，职责严格区分：

```
myNixOSConfig/
├── README.md                  # 项目总览、目录结构、重建命令、新机部署
├── AGENTS.md                  # LLM 上下文：硬件/系统信息、目录结构、服务列表、注意事项
├── wiki/                      # 操作手册 — 回答「怎么用」，含故障排查
│   ├── README.md              # wiki 导航首页（分类 MOC）
│   ├── _sources.yaml          # 来源映射清单（单真源，供审查使用）
│   ├── overview.md            # 项目概述
│   ├── architecture/          # 系统架构: index/flake/host
│   ├── desktop/               # 桌面环境: hyprland/fcitx5/noctalia/shell/darkmode/keyring
│   ├── productivity/          # 生产力: office
│   ├── dev/                   # 开发与工具: nvim/vscode/yazi/distrobox/bottles
│   ├── leisure/               # 娱乐: gaming/media
│   ├── networking/            # 网络与代理: mihomo
│   ├── security/              # 安全与隐私: index/sops/pam
│   ├── customization/         # 定制与扩展: overlays
│   ├── services.md            # 系统服务聚合
│   ├── deployment.md          # 部署与维护
│   ├── troubleshooting.md     # 故障排除聚合（链接各文档排查节 + issues/archived）
│   └── constraints.md         # 约束与惯例
└── memory/                    # 决策记忆 — 回答「为什么」，AI 决策参考
    ├── INDEX.md               # 卡片索引（AI 查询入口）
    ├── _template.md           # 卡片模板
    └── cards/                 # 原子化卡片（完整清单见 INDEX.md）
```

**核心区分**：wiki 存「怎么用」的稳定手册；memory 存「为什么这么配」的决策卡片。故障排查归 wiki，不迁入 memory。

## Wiki 文档规范

所有 wiki 文档遵循统一风格（参照 `wiki/desktop/hyprland.md`）：

- **语言**：中文
- **格式**：Markdown，使用 `#` 层级标题
- **核心元素**：
  - 表格 — 用于快捷键、配置项、选项说明等结构化信息
  - 代码块 — 用于命令、配置示例
  - 工作流示例 — 展示常见操作流程
  - 故障排查 — 每个文档末尾包含常见问题和解决方法
- **长度**：每个文档 80-200 行，保持简洁可扫描
- **表述**：面向使用者，描述"怎么用"而非"怎么配"。nix 配置细节留在 nix 文件里，文档说清用户需要知道什么

### 来源映射清单（单真源）

`wiki/_sources.yaml` 是文档与 nix 模块 / memory 卡之间的**唯一绑定表**。每篇 wiki 文档声明它派生自哪些 `.nix` 文件、关联哪些 memory 卡。所有反向映射（nix → docs）都从此表实时计算，不手维。

**不变式**（由本 skill 和提交前人工检查）：
1. 每个 `host/*.nix` 与 `home/**/*.nix` 模块至少被一篇文档的 `sources` 引用。
2. 每篇文档 `sources` 里列出的文件均真实存在。
3. 每篇文档 `memory` 里列出的卡在 `memory/cards/<slug>.md` 存在。

**工作流**：改了某个 `.nix` → 读 `_sources.yaml` 反查受影响文档集 → 按三方合并规则更新正文 + 刷新 frontmatter `updated`。新增/删除 wiki 文档或新增 nix 模块时，必须同步本清单。

### 来源与保留规则

- `wiki/_sources.yaml` 是唯一的 Nix→wiki→memory 映射；不要为某个目录再写硬编码清单。
- 每个 `sources` 路径必须真实存在，每个 `memory` slug 必须对应 `memory/cards/<slug>.md`。
- 现有 wiki 章节和用户措辞优先保留；源码只负责校正技术事实，Why 通过 memory 相关链接表达。
- 发现 Docusaurus、MkDocs 或其他既有文档系统时不迁移、不重命名；若没有安全的更新边界，报告
  `present_but_not_upgraded`，不要整篇覆盖。
- 只记录能帮助未来 agent 作出更好决定的持久上下文；普通编辑、每次测试和 routine Git 历史不写日志。

### 文档更新规则

wiki 文档以现有手册为基础，结合当前 Nix 配置和 memory 决策卡维护。

- **骨架/标题层级**：保留现有结构；只有在结构确实过时时才调整。
- **怎么用**（快捷键/工作流/排查命令）：取手写 wiki，优先级最高。
- **模块级事实**（技术栈/编码规范/特殊配置命令/架构设计）：以当前源文件为准。
- **为什么/决策**：**不内联**，改为末尾 `## 相关链接` 反向链接 `memory/cards/*`。
- **丢弃**：易失效的行号引用；源码指向使用不带行号的模块名或相对链接。
- **补项目规范**：frontmatter（`title/category/tags/updated`）；>150 行加 TOC；末尾固定 `## 相关链接`。

### 分类规则

`wiki/` 下按 `architecture/`、`desktop/`、`productivity/`、`dev/`、`leisure/`、`networking/`、`security/`、`customization/` 分类子目录。新增文档时先判断归属类别；跨领域约束放顶层 `constraints.md`。每篇文档带 frontmatter（`title`/`category`/`tags`/`updated`），>150 行加 TOC，末尾固定 `## 相关链接` 区块用 markdown 相对链接互链 + 反链相关 memory 卡。

当新增 nix 模块时，判断是否需要创建对应的 `wiki/<分类>/*.md`。判断标准：
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
- **再读已有文档**：至少读 `wiki/desktop/hyprland.md` 作为风格参考，读 `AGENTS.md` 了解系统上下文
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
- `wiki/_sources.yaml` — **必须**添加本条目的 sources + memory 绑定
- `wiki/README.md` — 导航首页中加入新文档的链接
- `README.md` — 目录结构部分是否需要加入新文档的说明
- `AGENTS.md` — 目录结构中是否需要补充新组件信息

## 变更驱动更新（清单工作流）

当用户修改 nix 配置后，按以下流程同步 wiki：

1. 读取变更的 `.nix` 文件列表（git diff 或用户告知）。
2. 读 `wiki/_sources.yaml`，反查「哪些文档的 `sources` 包含这些 nix」→ 得到「应更新文档集」。
3. 对集合中每篇文档：读源 nix + 读 wiki 文件 → 找出不一致处 → 按三方合并规则只改受影响部分。
4. 刷新文档 frontmatter 的 `updated` 字段。
5. 若本次改动涉及非显而易见的决策，**同步补一张 memory 决策卡**。
6. 若变更的 nix 文件在 `_sources.yaml` 中**无任何文档引用** → 提示用户先登记清单，或判断是否需要新建文档。
7. 若新增/删除 wiki 文档 → 同步 `_sources.yaml`。

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
2. 读 `wiki/_sources.yaml` 反查受影响文档集
3. 对集合中每篇文档，找出不一致的地方
4. 只修改文档中受影响的部分，保留其他内容不变
5. 刷新 frontmatter `updated`
6. 如果是 AGENTS.md 受影响，同步更新

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
4. 同时检查 README.md 的目录结构是否与实际一致，AGENTS.md 的服务列表是否完整
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

## AGENTS.md 维护

AGENTS.md 是给 LLM 的上下文，需要保持精确。包含：
- 硬件信息（通常不变）
- 系统详情（hostname、用户、服务等）
- 目录结构（与 README.md 同步）
- 已启用服务列表
- LiteLLM 模型映射表
- Nix 配置参数
- 注意事项（硬规则，含「决策记忆」规则）

当以下情况发生时更新 AGENTS.md：
- 新增/删除服务 → 更新服务列表
- 模型映射变更 → 更新 LiteLLM 表格
- 新增/删除 nix 模块 → 更新目录结构
- 配置规则/注意事项变化 → 更新对应部分
- 硬件变更 → 更新硬件信息

修改 AGENTS.md 时：
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

## 审查结果与交接

- `pass`：来源、导航、frontmatter、正文和 memory 关联均与当前配置一致。
- `warn`：证据不足、可安全跳过或已有内容没有安全更新边界；必须写明原因和下一步。
- `fail`：根目录错误/歧义、覆盖用户内容、来源路径失效、memory 索引缺失，或把推测写成事实。

每次运行结束都报告：

```text
Mode: <bootstrap|create|update|sync|record_decision|audit>
Target: <component or path>
Created/updated: <files or none>
Preserved: <files or none>
Skipped/blocked: <item + reason or none>
Unknowns: <items or none>
Validation: <checks and result>
Next action: <one concrete action>
```

## 禁止模式

- 只看 diff hunk 就改文档，忽略完整 Nix 源文件、import 链或现有手册。
- 为套用外部模板新增第二份来源、计划或 memory 体系。
- 把源码无法证明的 Why 写成确定结论，或用 filler card 填充索引。
- 未经确认移动/删除/覆盖用户文档，或用一次性脚本静默改完整 wiki。
- 把 parse、dry-build 或文档检查说成系统已 switch 或运行时已验证。
