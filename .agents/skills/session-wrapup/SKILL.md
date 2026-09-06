---
name: session-wrapup
description: >
  会话收尾时回顾 ~/myNixOSConfig 的改动、用户决策和未解决问题，判断是否需要更新 memory 或 wiki，
  并输出清晰交接。当用户说“收尾”“总结这次”“会话结束”“wrap up”“回顾一下”“值得记的决策”、
  “更新 memory”或“补 wiki”时使用。流程覆盖 worktree 检查、决策分类、计划/验证状态和持久化门禁；
  不负责 commit、push、rebuild 或大范围清理。
---

# 会话收尾：沉淀决策 + 核查 wiki

IRON LAW: 只沉淀会改变未来决策的持久知识；不把每次测试、普通 commit 或临时排障过程写成永久记忆。

此 skill 用于 NixOS 配置仓库 (`~/myNixOSConfig`) 的会话收尾，保证「每次会话更新 memory、每次 commit 更新 wiki」的纪律落地。

## 职责边界

- 本 skill 负责回顾对话和判断持久化内容；`wiki-maintainer` 负责实际文档、来源映射和卡片格式。
- `project-commit` 负责提交；收尾不替用户 commit，也不改变系统运行状态。
- 外部 docs-first workflow 的计划、同步和未知项原则在本仓库映射到现有 `wiki/`、`memory/`、
  `wiki/_sources.yaml` 和 `memory/INDEX.md`，不新增平行知识库。

## 触发时机

用户说"收尾"、"总结"、"会话结束"，或会话即将结束、用户准备离开时。**不要主动打断用户工作流**，只在用户暗示会话结束或明确要求时运行。

## 流程

### Step 0: 建立上下文 ⛔ BLOCKING

收尾先定位项目和 worktree，不把当前目录或分支名当作充分证据：

```bash
git status --short
git diff HEAD --stat
git ls-files --others --exclude-standard
git log --oneline -5
```

同时回顾对话中的判断、纠正、验证结果和未决问题。保留无关 staged、unstaged、untracked 改动，
不使用 `git reset`、`git checkout` 或 `git clean`。

### Step 1: 回顾本次会话

收集本次会话的改动全貌：

```bash
git status --short
git diff HEAD --stat        # 已改动文件概览
git log --oneline -5        # 最近提交
```

同时回顾**对话中的决策**（不只代码）：本次会话用户做了哪些判断、解决了哪些问题、纠正过什么方向。

### Step 2: 判断是否有值得沉淀的决策 ⚠️ REQUIRED

用 wiki-maintainer 的判定标准：**「为什么这么改」从 nix 代码 / commit message 推不出来 → 需要一张决策卡**。

逐项问：如果未来 agent 看不到这条信息，是否可能作出不同或更不安全的决定？如果不能，留在对话或 Git
历史中，不创建 filler card。

具体判断（满足任一即需卡片）：
- 配置的值带有一个非显而易见的权衡（为什么用 A 不用 B）
- 解决了某个隐蔽的坑，根因不是一眼能看出的
- 硬件特性 / 环境约束（如某设备、某路径、某端口）
- 用户明确表达的偏好或策略（如"以后 AI 工具先用 llm-agents.nix"）
- 用户纠正了某方向的偏差，这个教训值得记住

**不需要卡片的情况**：
- 只是加了几个包、改了个快捷键（操作手册级别的变化，代码可读）
- 纯内部重构、无用户可见变化
- 决策已能从 commit message / wiki 现有内容充分体现

### Step 3: 准备持久化变更 ⚠️ REQUIRED

仅“总结/收尾”而未明确要求写入时，先展示拟新增/更新的卡片、slug、理由和未知项；非小型写入等待用户确认。
用户明确要求“更新 memory/补 wiki”后，也先给出最小变更范围，再写入。移动、重命名、删除或覆盖已有内容必须单独确认。

有值得沉淀的决策时：

1. 用 `memory/_template.md` 为骨架，写 `memory/cards/<slug>.md`
2. frontmatter：`id`（=slug）、`type`（decision/hardware/constraint）、`tags`、`date`
3. 正文：问题 → 决策 → Why → How to apply，末尾 `相关:` 交叉引用
4. **必须同步更新 `memory/INDEX.md`** 对应分组

无新决策时，明确说明"本次无新决策，无需更新 memory"，**不要为凑数写卡**。

### Step 4: 核查 wiki 同步 ⚠️ REQUIRED

检查本次改动是否动了 wiki 需要覆盖的内容：

- 改了用户可见行为（快捷键/默认值/新组件）→ wiki 对应手册是否已更新？
- 新决策卡是否引用了 wiki？wiki 相关文档是否需要补链接？
- 若提交前检查发现 wiki/memory 遗漏 → 补齐后再提交

若有遗漏，用 wiki-maintainer 更新 wiki 并提醒用户一起 commit。

如果本次完成了已有计划的 execution unit，检查其 verification、completion gate、当前 unit 和下一步；只有验证已记录
或明确 deferred 时才能标记完成。不要为一次普通 commit 新建计划或日志。

### Step 5: 验证与报告

对任何写入的卡片或文档检查 frontmatter、索引、相对链接、相关 wiki 反链和 `_sources.yaml` 映射；运行
`git diff --check`，并另行检查未跟踪文件。文档检查不等于 Nix build、switch 或 live runtime 验证。

向用户简洁报告：

```
## 会话收尾

**memory**: 新增/更新 <N> 张卡（<slug>） / 本次无新决策
**wiki**: 同步了 <文件> / 已是最新
**未提交改动**: <文件列表，若需 commit 提醒>
**跳过/阻塞/未知**: <项目与原因> / 无
**验证**: <命令与结果>
**下一步**: <一个具体动作>
```

结果使用 `pass`（已同步）、`warn`（证据不足或安全跳过）和 `blocked`（需要用户决定）；每个 warn/blocked 都要
说明原因与最安全的下一步，不要静默忽略。

## 禁止模式

- 把每次测试、普通 commit、临时日志或显而易见的配置写成 memory 卡。
- 从分支名或单个 diff 推断用户意图，编造回溯 Why 或补齐未知事实。
- 为了“收尾”自动 commit、push、rebuild、deploy，或清理无关 dirty 文件。
- 未确认就覆盖、移动、删除已有卡片、wiki 页面或索引。

## 与 commit 的关系

- 若本次会话有改动未 commit，且涉及 `.nix` 改动 → 提交前必须完成 wiki/memory 同步。本 skill 在 commit 前运行可避免遗漏。
- commit 动作本身由 project-commit skill 处理，本 skill 只负责**知识沉淀**，不替代 commit。

## 质量标准

每张卡都应让读者回答：遇到什么问题？做了什么决策？为什么（Why）？后续怎么遵守（How to apply）？
