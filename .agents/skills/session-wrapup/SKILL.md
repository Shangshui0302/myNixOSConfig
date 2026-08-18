---
name: session-wrapup
description: >
  会话收尾时沉淀决策到 memory 并核查 wiki 同步。当用户说"收尾"、"总结这次"、"会话结束"、"wrap up"、
  "回顾一下"、"该沉淀了"、或任何会话即将结束的信号时，必须使用此 skill。也用于用户要求"检查有没有
  值得记的决策"、"更新 memory"、"补 wiki"。流程：回顾本次改动与对话 → 判断是否有非显而易见的决策 →
  有则写 memory 卡 + 更新 INDEX → 检查 wiki 是否漏同步 → 报告结果。简而言之，任何会话结束时的知识
  沉淀操作都触发此 skill。
---

# 会话收尾：沉淀决策 + 核查 wiki

此 skill 用于 NixOS 配置仓库 (`~/myNixOSConfig`) 的会话收尾，保证「每次会话更新 memory、每次 commit 更新 wiki」的纪律落地。

## 触发时机

用户说"收尾"、"总结"、"会话结束"，或会话即将结束、用户准备离开时。**不要主动打断用户工作流**，只在用户暗示会话结束或明确要求时运行。

## 流程

### Step 1: 回顾本次会话

收集本次会话的改动全貌：

```bash
git status
git diff HEAD --stat        # 已改动文件概览
git log --oneline -5        # 最近提交
```

同时回顾**对话中的决策**（不只代码）：本次会话用户做了哪些判断、解决了哪些问题、纠正过什么方向。

### Step 2: 判断是否有值得沉淀的决策

用 wiki-maintainer 的判定标准：**「为什么这么改」从 nix 代码 / commit message 推不出来 → 需要一张决策卡**。

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

### Step 3: 写卡 + 更新 INDEX

有值得沉淀的决策时：

1. 用 `memory/_template.md` 为骨架，写 `memory/cards/<slug>.md`
2. frontmatter：`id`（=slug）、`type`（decision/hardware/constraint）、`tags`、`date`
3. 正文：问题 → 决策 → Why → How to apply，末尾 `相关:` 交叉引用
4. **必须同步更新 `memory/INDEX.md`** 对应分组

无新决策时，明确说明"本次无新决策，无需更新 memory"，**不要为凑数写卡**。

### Step 4: 核查 wiki 同步

检查本次改动是否动了 wiki 需要覆盖的内容：

- 改了用户可见行为（快捷键/默认值/新组件）→ wiki 对应手册是否已更新？
- 新决策卡是否引用了 wiki？wiki 相关文档是否需要补链接？
- 若提交前检查发现 wiki/memory 遗漏 → 补齐后再提交

若有遗漏，用 wiki-maintainer 更新 wiki 并提醒用户一起 commit。

### Step 5: 报告

向用户简洁报告：

```
## 会话收尾

**memory**: 新增/更新 <N> 张卡（<slug>） / 本次无新决策
**wiki**: 同步了 <文件> / 已是最新
**未提交改动**: <文件列表，若需 commit 提醒>
```

## 与 commit 的关系

- 若本次会话有改动未 commit，且涉及 `.nix` 改动 → 提交前必须完成 wiki/memory 同步。本 skill 在 commit 前运行可避免遗漏。
- commit 动作本身由 project-commit skill 处理，本 skill 只负责**知识沉淀**，不替代 commit。

## 质量标准

每张卡都应让读者回答：遇到什么问题？做了什么决策？为什么（Why）？后续怎么遵守（How to apply）？
