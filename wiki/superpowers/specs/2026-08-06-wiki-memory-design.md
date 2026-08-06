# Wiki + 卡片式 Memory — 设计文档

**日期**: 2026-08-06
**状态**: 待实施
**范围**: `docs/` → `wiki/` 迁移、新建 `memory/` 决策卡、skill 改名与扩展、commit 工作流联动

## 1. 背景与目标

当前文档体系有两个问题：

1. `docs/` 是 11 个扁平 markdown 文件，无统一导航首页，组件间缺乏组织
2. 大量「为什么这么配」的决策知识散落在对话历史、auto-memory、CLAUDE.md 注释中，AI agent 和用户都难以按需检索

目标：

- **wiki/**：取代 `docs/`，成为操作手册（含故障排查），带导航首页
- **memory/**：新建卡片式决策记忆，存「从代码推不出来的知识」——决策（Why）、硬件特性、约束
- **skill 升级**：`doc-maintainer` → `wiki-maintainer`，职责扩展为 wiki + memory 双维护
- **commit 联动**：wiki/memory 更新必须与代码改动在同一 commit 内

## 2. 目标目录结构

```
myNixOSConfig/
├── wiki/                      # 取代 docs/ — 操作手册（含故障排查）
│   ├── README.md              # wiki 首页：组件索引 + 分类导航
│   ├── constraints.md         # 迁移自 nixos-constraints.md（约束规范）
│   ├── hyprland.md / noctalia.md / shell.md / mihomo.md / litellm.md
│   ├── nvim.md / distrobox.md / yazi.md / darkmode.md / bottles-offline-workaround.md
│   └── superpowers/specs/     # 设计文档归档（随 git mv 迁入）
├── memory/                    # 卡片式 memory — AI 决策记忆
│   ├── INDEX.md               # 卡片索引（AI 查询入口）
│   ├── _template.md           # 卡片模板
│   └── cards/                 # 原子化卡片
│       ├── mihomo-tun-stack.md          # decision
│       ├── ai-tools-source.md           # decision
│       ├── flake-unstable-strategy.md   # decision
│       ├── nix-search-before-manual.md  # constraint
│       └── ...                # 后续按规则逐张补
├── docs/                      # git mv 后删除
└── CLAUDE.md / README.md / AGENTS.md  # 引用路径同步更新
```

## 3. 迁移动作（保留 git 历史）

```bash
git mv docs/ wiki/
git mv wiki/nixos-constraints.md wiki/constraints.md
```

`docs/superpowers/specs/` 随目录整体迁入，落在 `wiki/superpowers/specs/`，作为 wiki 设计背景归档。

## 4. memory 卡片格式

**文件**: `memory/cards/<slug>.md`

```markdown
---
id: <slug>
type: decision          # decision | hardware | constraint
tags: [<分类>, ...]
date: YYYY-MM-DD
---

# <标题>

## 问题
<背景：遇到什么问题>

## 决策
<做了什么 / 具体配置>

## Why
<为什么这么做——代码里看不出来的原因>

## How to apply
<后续怎么遵守：改这块配置时要注意什么>

相关: [[wiki/<手册>#<锚点>]]  |  [[memory/cards/<其他卡>]]
```

### 字段说明

| 字段 | 取值 | 含义 |
|------|------|------|
| `id` | kebab-case | 卡片唯一标识，等于文件名 slug |
| `type` | `decision` / `hardware` / `constraint` | 卡片类别 |
| `tags` | 数组 | 便于按组件/主题过滤 |
| `date` | `YYYY-MM-DD` | 决策日期 |

### 三种类型

| 类型 | 存什么 | 例子 |
|------|--------|------|
| `decision` | 非显而易见的配置决策（Why 代码看不出来） | mihomo 为什么 gvisor + mtu 1500；AI 工具为什么优先 llm-agents.nix |
| `hardware` | 硬件特性、环境约束 | MS CJK 字体在 `/persist/Fonts/`；2K 屏 scale 1.5；flake.lock root 拥有 |
| `constraint` | 必须遵守的硬规则 | 查包强制多路径搜索；所有改动必须走 nix |

**不存什么**：操作手册内容（归 wiki）、踩坑过程细节（归 wiki 故障排查）、显而易见的配置（代码能看出来）。

## 5. memory 索引与模板

**`memory/INDEX.md`** — AI 查询入口，按 type 分组列出全部卡片：

```markdown
# Memory 索引 — AI 决策记忆

遇到「为什么这么配」「历史决策」「硬件特性」问题时，先查本索引。

## 决策 decision
- [<标题>](cards/<slug>.md) — <一句话摘要>
## 硬件 hardware
- ...
## 约束 constraint
- ...
```

**`memory/_template.md`** — 空白骨架，新建卡片时复制。

## 6. AI 集成

**CLAUDE.md + AGENTS.md**「注意事项」区各加一条：

```markdown
- **决策记忆**：遇到「为什么这么配」「历史决策」「硬件特性」问题，先查 `memory/INDEX.md`，找到对应卡片再动手；改配置前若涉及已知决策，读相关卡片确认不冲突
```

## 7. skill 改名与扩展

`.agents/skills/doc-maintainer/` 与 `.claude/skills/doc-maintainer/`（两份相同副本）改名为 **`wiki-maintainer`**：

```
.agents/skills/wiki-maintainer/SKILL.md
.claude/skills/wiki-maintainer/SKILL.md
```

### 职责变化

| 项 | 旧 (doc-maintainer) | 新 (wiki-maintainer) |
|----|--------------------|---------------------|
| 维护对象 | `docs/*.md`, README, CLAUDE.md | `wiki/*.md`, README, CLAUDE.md, **`memory/`** |
| 文档结构 | docs/ 扁平 | wiki/ + 导航首页 README.md |
| 决策记忆 | 无 | **新增**：改配置涉及非显而易见 Why → 写/更新 `memory/cards/*.md` + INDEX |
| 触发词 | 写文档/更新文档/docs | + wiki/memory/决策卡 |

**判定是否需要决策卡的规则**：改配置时若「为什么这么改」从 nix 代码/commit message 推不出来 → 需要一张决策卡。判断标准：配置的值带有一个非显而易见的权衡，且未来可能有人（或 AI）想改掉它。

### project-commit skill 联动

`.agents/skills/project-commit/SKILL.md` + `.claude/skills/project-commit/SKILL.md` Step 2「决定需要更新哪些文档」扩展：

| 改动类型 | 必查项 |
|---------|--------|
| 用户可见行为变更（快捷键/默认值/新功能） | wiki 对应手册 |
| 非显而易见的决策（Why 代码看不出来） | memory 决策卡 |
| 新组件 / 删除组件 | wiki 导航首页 README.md |
| 硬件特性 / 环境约束变化 | memory 硬件/约束卡 |

**联动规则**：改动涉及以上任一项时，wiki/memory 更新必须与代码改动在**同一 commit** 内完成，不允许只提交代码。commit message 的 scope 反映组件名。

## 8. 引用路径同步清单

| 文件 | 需改内容 |
|------|---------|
| `README.md` | 目录结构：`docs/` → `wiki/`（含文件列表）+ 新增 `memory/` |
| `CLAUDE.md` | 目录结构 `docs/` → `wiki/` + `memory/`；注意事项「查阅 docs/」→「查阅 wiki/」；新增决策记忆规则 |
| `.agents/AGENTS.md` | 同上（CLAUDE.md 的迁移版，两处保持同步） |
| `.agents/skills/doc-maintainer/` | 改名为 wiki-maintainer，全部 `docs/` 引用 → `wiki/`，新增 memory 维护章节 |
| `.claude/skills/doc-maintainer/` | 同上（副本） |
| `.agents/skills/project-commit/` | `docs/*.md` → `wiki/*.md`，引用 doc-maintainer → wiki-maintainer，新增联动规则 |
| `.claude/skills/project-commit/` | 同上（副本） |

## 9. 初始决策卡清单

从现有 auto-memory + 本会话已知决策迁移，首批 4 张：

| 卡片 slug | 类型 | 来源 |
|-----------|------|------|
| `mihomo-tun-stack` | decision | 本会话：nix 下载慢 → gvisor + mtu 1500 |
| `ai-tools-source` | decision | auto-memory `reference_llm_agents_nix.md`：AI 工具优先 llm-agents.nix，需安全审查 |
| `flake-unstable-strategy` | decision | 本会话：全 unstable，出问题再修 |
| `nix-search-before-manual` | constraint | auto-memory `feedback_nix_search_before_manual.md`：查包强制多路径 |

其余 auto-memory（如 `workflow_update_docs_commit_rebuild`、`feedback_debug_config_before_architecture`）属于个人工作习惯，保留在 `~/.claude/.../memory/`，不迁入项目 memory。

## 10. 验证与验收

- [ ] `git mv` 迁移成功，git 历史保留
- [ ] `grep -rn "docs/"` 全仓库无残留引用（除 wiki/superpowers/specs 设计文档历史）
- [ ] `memory/INDEX.md` 与 `cards/` 实际文件一一对应
- [ ] skill 改名后 `.agents/` 与 `.claude/` 两份副本一致
- [ ] 文档纯文本改动，无需 `nixos-rebuild dry-build`（无 nix 结构变更）
- [ ] commit message 体现本次范围：`docs(wiki): migrate docs → wiki + add memory cards`

## 11. 分步实施顺序

1. `git mv docs/ wiki/` + `git mv wiki/nixos-constraints.md wiki/constraints.md`
2. 新建 `memory/`（INDEX.md + _template.md + 4 张初始卡）
3. 编写 `wiki/README.md` 导航首页
4. 改 skill 名（两份 doc-maintainer → wiki-maintainer）+ 扩展内容
5. 改 project-commit skill（两份）加联动规则
6. 同步 README.md / CLAUDE.md / AGENTS.md 引用
7. 全局 grep 校验 `docs/` 残留
8. commit
