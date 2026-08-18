---
id: ai-tools-source
type: decision
tags: [ai, tools, packaging]
date: 2026-08-05
---

# AI 工具优先用 numtide/llm-agents.nix 的包

## 问题
装 AI 相关工具时，之前是自己打包（`local-deriv/` 手写 derivation），费时且可能踩 Electron/deb 打包的坑。发现第三方仓库 `numtide/llm-agents.nix` 已有大量现成 Nix 包。

## 决策
以后装任何 AI 相关工具，**先查 [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix) 有没有现成的包**，有就用它的。**但必须做安全审查**。仓库自带的安全审查要求：
- 检查 derivation（source 来源、是否 fetch 远程脚本、patch 内容），确认无恶意后才用

当前使用的包：`codex`、`officecli`；`cc-switch` 和其他工具按需从已审查来源加入。

## Why
- 用户指定这是 AI 工具优先来源，避免自己打包
- 但第三方包有供应链风险，必须审查后才能用
- 使用方式：flake 加 `llm-agents` input，从 `inputs.llm-agents.packages.<system>.<name>` 取包

## How to apply
- 装 AI 工具前先 `gh api repos/numtide/llm-agents.nix/contents/packages` 查有没有现成包
- 用之前审查其 derivation
- 没有现成包才走 `local-deriv/` 自己打包

补充案例（2026-08-09）：`rtk`（rtk-ai/rtk）与 `codebase-memory-mcp` 不在 llm-agents 清单里。codebase-memory-mcp 用 nixpkgs 现成包；rtk 因 nixpkgs 里同名的是 C++ 数学库 exprtk（撞名），走了 `local-deriv/rtk.nix` 用官方 musl 静态二进制自打包。
