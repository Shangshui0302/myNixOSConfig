---
id: docs-sync-automation
type: decision
tags: [workflow, git, documentation]
date: 2026-08-07
---

# 文档同步：清单驱动审查 + skills

## 问题
「每次会话更新 memory、每次 commit 更新 wiki」的纪律需要一个简单、可审查的流程。脚本无法理解 diff 并写文档，内容维护由 skills 完成，来源清单负责发现遗漏。

## 决策
单一来源（`wiki/_sources.yaml` 清单 + `wiki-maintainer` / `project-commit` / `session-wrapup` skills）：
1. **清单 `wiki/_sources.yaml`**：每篇 wiki 文档声明派生自哪些 `.nix` + 关联哪些 memory 卡。反向映射（nix→docs）由 skill/hook 从此表实时计算。
2. **commit→wiki 人工门禁**：`project-commit` 读取 staged 的 `.nix`，经清单反查应更新文档集，并在提交前报告遗漏。
3. **会话→memory skill**：`session-wrapup` 会话结束前回顾决策，必要时写卡 + 更新 INDEX，并核查 wiki。

## Why
- **清单驱动比硬编码精准**：旧实现硬编码 desktop/networking/dev 路径，新增目录或模块即失效。清单把「nix→docs」绑定显式化，hook/skill 共用同一份真源。
- **skill 只负责提醒和审查，不伪造自动修改**：内容生成需要理解 diff 语义，应保留人工确认。

## How to apply
- 清单不变式：每个 `host/`+`home/` 的 nix 模块至少被一篇文档引用；每篇文档的 sources 文件均存在；每篇文档的 memory 卡均存在
- 改了某个 `.nix` → 读清单反查受影响文档集 → 按三方合并规则更新正文 + 刷新 frontmatter `updated`
- 新增/删除 wiki 文档或新增 nix 模块时，必须同步清单
- 新决策判断交给 session-wrapup skill，不要为凑数写卡

相关: [[wiki-memory-layering]] | [[workflow_update_docs_commit_rebuild]]
