---
id: docs-sync-automation
type: decision
tags: [workflow, hook, git, automation]
date: 2026-08-07
---

# 文档同步自动化：清单驱动 hook 门禁 + session-wrapup skill

## 问题
「每次会话更新 memory、每次 commit 更新 wiki」的纪律怎么机械化保证？脚本 hook 无法理解 diff 并写文档（内容必须 AI 生成），所以自动化只能做两件事：**触发 AI 去写**（skill/提示）或**拦截校验**（hook 阻止 commit）。

## 决策
三方单真源（`wiki/_sources.yaml` 清单 + `wiki-maintainer` skill + `.claude/hooks/check-doc-sync.sh` hook）：
1. **清单 `wiki/_sources.yaml`**：每篇 wiki 文档声明派生自哪些 `.nix` + 关联哪些 memory 卡。反向映射（nix→docs）由 skill/hook 从此表实时计算。
2. **commit→wiki 硬门禁**：hook 拦截 `git commit`。读 staged 的 `.nix` → 经清单反查「应更新文档集」→ 若该集合中无任何文档（也无关联 memory 卡）被 staged → `deny`，并列出具体该改的文档名。staged 的 nix 未在清单登记 → 拦住并提示先登记。
3. **会话→memory skill**：`session-wrapup` skill，会话结束前运行，回顾会话 → 判断非显而易见决策 → 写卡 + 更新 INDEX → 核查 wiki。

## Why
- **清单驱动比硬编码精准**：旧实现硬编码 desktop/networking/dev 路径，新增目录或模块即失效。清单把「nix→docs」绑定显式化，hook/skill 共用同一份真源。
- **hook 只能拦截不能写**：内容生成需要理解 diff 语义，只能 AI 做。hook 是硬约束兜底，skill 是主动触发，分工不同。
- **matcher vs if**：`matcher: "Bash"` 匹配 tool_name，`if: "Bash(git commit *)"` 匹配命令内容。`if` 对含 `$()`/`$VAR` 的命令 **fail open**，脚本必须自查命令确实是 git commit。
- **hook 决定优先于权限 allow**：即使 `Bash(git commit:*)` 在 allowlist，hook 的 deny 仍拦截——真门禁。
- **只拦 AI 发起的 commit**：脚本无法覆盖用户终端手动 commit（要覆盖得用 git 原生 pre-commit hook）。
- **项目级 settings.json**：`.claude/settings.json` 可提交进 git，clone 后门禁自带；`.settings.local.json` 才 gitignore。

## How to apply
- 清单不变式：每个 `host/`+`home/` 的 nix 模块至少被一篇文档引用；每篇文档的 sources 文件均存在；每篇文档的 memory 卡均存在
- 改了某个 `.nix` → 读清单反查受影响文档集 → 按三方合并规则更新正文 + 刷新 frontmatter `updated`
- 新增/删除 wiki 文档或新增 nix 模块时，必须同步清单
- 改 hook 后需**重启 Claude Code 会话**才生效（启动时加载 settings.json）
- 新决策判断交给 session-wrapup skill，不要为凑数写卡

相关: [[wiki-memory-layering]] | [[workflow_update_docs_commit_rebuild]]
