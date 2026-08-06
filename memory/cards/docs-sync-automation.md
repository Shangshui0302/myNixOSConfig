---
id: docs-sync-automation
type: decision
tags: [workflow, hook, git, automation]
date: 2026-08-06
---

# 文档同步自动化：hook 门禁 + session-wrapup skill

## 问题
「每次会话更新 memory、每次 commit 更新 wiki」的纪律怎么机械化保证？脚本 hook 无法理解 diff 并写文档（内容必须 AI 生成），所以自动化只能做两件事：**触发 AI 去写**（skill/提示）或**拦截校验**（hook 阻止 commit）。

## 决策
双机制：
1. **commit→wiki 硬门禁**：项目级 PreToolUse hook（`.claude/hooks/check-doc-sync.sh`）拦截 `git commit`。若 pending 改动含 `*.nix` 但无 `wiki/` 或 `memory/` 文件 → `deny`，reason 提示跑 `/wiki-maintainer`。
2. **会话→memory skill**：`session-wrapup` skill，会话结束前运行，回顾会话 → 判断非显而易见决策 → 写卡 + 更新 INDEX → 核查 wiki。

## Why
- **hook 只能拦截不能写**：内容生成需要理解 diff 语义，只能 AI 做。hook 是硬约束兜底，skill 是主动触发，分工不同。
- **matcher vs if**：`matcher: "Bash"` 匹配 tool_name，`if: "Bash(git commit *)"` 匹配命令内容。`if` 对含 `$()`/`$VAR` 的命令 **fail open**，脚本必须自查命令确实是 git commit。
- **hook 决定优先于权限 allow**：即使 `Bash(git commit:*)` 在 allowlist，hook 的 deny 仍拦截——真门禁。
- **只拦 AI 发起的 commit**：脚本无法覆盖用户终端手动 commit（要覆盖得用 git 原生 pre-commit hook）。
- **项目级 settings.json**：`.claude/settings.json` 可提交进 git，clone 后门禁自带；`.settings.local.json` 才 gitignore。

## How to apply
- hook 逻辑：staged + unstaged tracked 文件取并集，`*.nix` 改了但 `wiki/*`、`memory/*` 都没改 → deny
- 误报处理：纯内部 .nix 重构（无用户可见变化）也会被拦，若频繁误报可把 `deny` 改 `ask`
- 改 hook 后需**重启 Claude Code 会话**才生效（启动时加载 settings.json）
- 新决策判断交给 session-wrapup skill，不要为凑数写卡

相关: [[wiki-memory-layering]] | [[workflow_update_docs_commit_rebuild]]
