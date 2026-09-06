---
name: project-commit
description: >
  When the user says “提交当前更改”“commit”“保存这批改动”“准备提交”或明确要保存一组变更时，
  在 ~/myNixOSConfig 中执行完整 worktree 审查、wiki/memory 门禁、Nix 结构验证、精确 staging、
  确认后 commit 和结果交接。不要把普通文件保存、“commit to memory”、push 或自动 rebuild 当作本 skill。
---

# Project Commit Workflow

IRON LAW: 未完成完整 worktree 审查、文档门禁、验证、精确文件清单和用户确认前，绝不创建 commit；
只 stage 批准的路径，默认不 push。

This skill handles the standard commit workflow for the NixOS config repo. Every commit
goes through context → review → docs → validation → confirm → commit, in that order.

## 职责边界

- `wiki-maintainer` 负责 wiki/memory/README/AGENTS 的内容与来源一致性；本 skill 只负责 Git 门禁。
- `session-wrapup` 负责会话决策回顾；commit 不自动生成 memory 卡。
- parse、dry-build、switch 和 live runtime 是不同证据层；提交成功不代表系统已经部署。

## Step 0: Establish Scope

Before reviewing or staging anything, inspect the complete worktree:

```bash
git status --short
git diff HEAD
git diff --cached
git ls-files --others --exclude-standard
git log --oneline -5
```

Identify exactly which paths the user wants in this commit. If staged, unstaged, or
untracked files mix unrelated work and the scope is unclear, stop and ask. Preserve
existing staging, branches, and dirty files; never use `git reset`, `git checkout`, or
`git clean` to make the worktree convenient.

## Step 1: Review the Diff

First, gather the full picture of what changed:

```bash
git diff HEAD --stat
git diff --name-status HEAD
```

Review for these project-specific issues:

- **Nix syntax**: Missing semicolons, unmatched braces, wrong indentation that could
  cause parse errors.
- **Import chain broken?** New nix files must be imported by their parent module
  (e.g., new `home/env/foo.nix` must appear in `home/base.nix` as an import).
- **Override vs overlay rule**: Modify an existing package with `overrideAttrs` when
  it is used in one place. New standalone packages go in `local-deriv/`, are imported
  directly, and expose a flake package build target — never create an overlay for one package.
- **Stale paths**: If a file was renamed/moved, are all import paths updated?
- **Hardcoded secrets**: No API keys, tokens, or passwords in nix files. Secrets
  belong in `/persist/secrets/`.
- **Deduplication**: Tools already declared in `host/network.nix`
  (dnsutils, iputils, tcpdump, mtr, nmap, iperf3, ethtool, iptables) should not
  appear in `home/` modules.
- **Fonts**: Custom fonts use a focused `local-deriv/<name>.nix`; shared system fonts
  are consumed from `host/base/desktop.nix`, with additional consumers only when required.

If anything looks wrong, flag it to the user before proceeding.

## Step 2: Decide What Documentation Needs Updating

Not every change needs wiki/memory updates. Use this matrix to decide:

| Change scope | Docs to check |
|-------------|--------------|
| New service or system daemon | README.md + AGENTS.md |
| New nix module file (host/ or home/ subdir) | README.md + AGENTS.md (directory structure) |
| Removed/renamed module file | README.md + AGENTS.md |
| Changed keybindings, gestures, or user-facing behavior | wiki/*.md + AGENTS.md |
| Non-obvious decision (why not derivable from code/commit) | memory decision card + INDEX.md |
| Hardware trait / environment constraint change | memory hardware/constraint card + INDEX.md |
| New/removed component | wiki/README.md (nav home) |
| New custom package in local-deriv/ | wiki/dev/nix-packaging.md + wiki/_sources.yaml + affected component wiki; README.md/AGENTS.md only if structure or rules changed |
| New overlay | Usually none |
| Adding/removing a flatpak or user app | Usually none |
| Tweak to an existing config value | Usually none |
| Typo fix, formatting, comment change | None |
| wiki/*.md content change | Just AGENTS.md (if doc list changed) |

When wiki/memory updates are needed, use the `wiki-maintainer` skill's patterns:
- README.md: update directory structure, service list, or deployment steps
- AGENTS.md: update directory structure, enabled services list, LiteLLM table, notes
- wiki/*.md: update keybindings, features, troubleshooting
- memory/cards/*.md + memory/INDEX.md: record decision/hardware/constraint cards

**Linkage rule**: when a change falls under any of the above rows, the wiki/memory
updates MUST land in the same commit as the code change — never commit code without
its docs. If **nothing** needs wiki/memory updates, say so explicitly — don't force one.

## Step 3: Dry-Build (Structural Changes Only)

Only run dry-build when the change involves:

- A new nix file (new module, new package, new overlay)
- Changed `imports` anywhere
- Moved/renamed files
- Changed flake.nix inputs or outputs

```bash
cd ~/myNixOSConfig && sudo nixos-rebuild dry-build --flake . 2>&1
```

Skip this step for: config value tweaks, adding/removing a package from an existing
`home.packages` list, flatpak entries, or doc-only changes.

If dry-build fails, report the error and stop — don't commit broken config.

Before presenting the summary, always run `git diff --check` and separately inspect
`git ls-files --others --exclude-standard`. A clean diff check does not prove that new
untracked files are correct. Report parse/build results separately from any later
activation or live runtime check; Codex does not run `nixos-rebuild switch` here.

## Step 4: Present Summary

Show the user a concise summary before committing:

```
## Commit Summary

**Changes:**
- <file> — <what changed>

**Wiki/Memory updated:**
- <wiki file / memory card> — <what was added/changed>
- (or "No wiki/memory updates needed")

**Validation:**
- `git diff --check` — passed / failed
- parse/dry-build — passed / skipped / failed
- other checks — <result>

**Unrelated dirty paths:**
- <path> / none

**Skipped/blocked/unknown:**
- <item + reason> / none

**Proposed commit:**
- `<type>(<scope>): <description>`
```

Let the user confirm before proceeding. If they say no, ask what needs adjusting.

## Step 5: Commit

After explicit confirmation, stage only the approved paths:

```bash
git add -- <approved-path> ...
git status --short
git diff --cached
```

Never use `git add -A` when unrelated work may exist. If the cached diff differs from
the confirmed summary, stop and show the discrepancy. Create the commit with a
conventional message format:

```
<type>(<scope>): <description>
```

Types: `feat`, `fix`, `refactor`, `chore`, `docs`
Scopes: component name matching the nix module (e.g., `hyprland`, `systools`,
  `nvim`, `shell`, `network`, `litellm`, `fonts`, `pkgs`)

Examples:
- `feat(systools): add SerialTest flatpak for serial port debugging`
- `fix(hyprland): swap resize/move keybindings`
- `refactor(overlays): deduplicate vim plugin aliases`

After committing, show the commit hash and subject. Do not push, create a PR, amend, or
rewrite history unless the user explicitly requests that separate action.

## Step 6: Remind to Rebuild

Remind the user to rebuild:

```bash
cd ~/myNixOSConfig && sudo nixos-rebuild switch --flake .
```

After rebuild, suggest a quick health check:

```bash
systemctl --failed --no-legend | head -5
```

## 禁止模式

- 用 `git add -A`、reset、clean 或 checkout 把无关工作带入提交或覆盖掉。
- 只提交代码而跳过 `wiki-maintainer` 的文档/来源门禁。
- 把 diff、parse 或 dry-build 结果冒充 activation、switch 或 live runtime 证明。
- 验证失败仍创建 commit，或未经用户确认自行 amend、push、建 PR。

## What This Skill Does NOT Do

- **Does not push** — push is manual for this private repo
- **Does not run rebuild** — the user runs it manually after reviewing the commit
- **Does not amend commits** — always creates new commits unless user explicitly asks
  for amend
- **Does not push or create PRs** — feature branches are used for risky changes
