---
name: project:commit
description: >
  When the user says they're ready to commit, save work, submit changes, 提交, or wrap up
  a set of changes in this NixOS config repo. This skill orchestrates the full commit
  workflow: review the diff for issues, update relevant documentation (README.md,
  AGENTS.md, docs/*.md), present a summary for confirmation, then create the commit.
  Use this skill for any commit in ~/myNixOSConfig — it ensures the "review → update
  docs → commit" discipline is followed every time. Do NOT trigger for: writing/saving
  a file to disk, "commit to memory", or git operations in other repos.
---

# Project Commit Workflow

This skill handles the standard commit workflow for the NixOS config repo. Every commit
goes through review → doc update → confirm → commit, in that order.

## Step 1: Review the Diff

First, gather the full picture of what changed:

```bash
git status
git diff HEAD
git log --oneline -5
```

Review for these project-specific issues:

- **Nix syntax**: Missing semicolons, unmatched braces, wrong indentation that could
  cause parse errors.
- **Import chain broken?** New nix files must be imported by their parent module
  (e.g., new `home/env/foo.nix` must appear in `home/default.nix` as an import).
- **Override vs overlay rule**: New packages added via `overrideAttrs` only if used in
  one place. New packages in nixpkgs only via overlays. New standalone packages go in
  `local-deriv/` and are imported directly — never put new packages in `nixpkgs.overlays`.
- **Stale paths**: If a file was renamed/moved, are all import paths updated?
- **Hardcoded secrets**: No API keys, tokens, or passwords in nix files. Secrets
  belong in `/persist/secrets/`.
- **Deduplication**: Tools already declared in `host/network.nix`
  (dnsutils, iputils, tcpdump, mtr, nmap, iperf3, ethtool, iptables) should not
  appear in `home/` modules.
- **Fonts**: New fonts go in `local-deriv/fonts.nix`, imported by `home/theme.nix`.

If anything looks wrong, flag it to the user before proceeding.

## Step 2: Decide What Documentation Needs Updating

Not every change needs doc updates. Use this matrix to decide:

| Change scope | Docs to check |
|-------------|--------------|
| New service or system daemon | README.md + AGENTS.md |
| New nix module file (host/ or home/ subdir) | README.md + AGENTS.md (directory structure) |
| Removed/renamed module file | README.md + AGENTS.md |
| Changed keybindings, gestures, or user-facing behavior | docs/*.md + AGENTS.md |
| New custom package in local-deriv/ | README.md + AGENTS.md |
| New overlay | Usually none |
| Adding/removing a flatpak or user app | Usually none |
| Tweak to an existing config value | Usually none |
| Typo fix, formatting, comment change | None |
| docs/*.md content change | Just AGENTS.md (if doc list changed) |

When doc updates are needed, use the `doc-maintainer` skill's patterns:
- README.md: update directory structure, service list, or deployment steps
- AGENTS.md: update directory structure, enabled services list, LiteLLM table, notes
- docs/*.md: update keybindings, features, troubleshooting

If **nothing** needs doc updates, say so explicitly — don't force one.

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

## Step 4: Present Summary

Show the user a concise summary before committing:

```
## Commit Summary

**Changes:**
- <file> — <what changed>

**Docs updated:**
- <doc file> — <what was added/changed>
- (or "No doc updates needed")

**Dry-build:** passed / skipped
```

Let the user confirm before proceeding. If they say no, ask what needs adjusting.

## Step 5: Commit

Create the commit with a conventional message format:

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

The commit must include the Co-Authored-By trailer:

```
Co-Authored-By: Antigravity <noreply@google.com>
```

After committing, show the commit hash.

## Step 6: Remind to Rebuild

Remind the user to rebuild:

```bash
cd ~/myNixOSConfig && sudo nixos-rebuild switch --flake .
```

After rebuild, suggest a quick health check:

```bash
systemctl --failed --no-legend | head -5
```

## What This Skill Does NOT Do

- **Does not push** — push is manual for this private repo
- **Does not run rebuild** — the user runs it manually after reviewing the commit
- **Does not amend commits** — always creates new commits unless user explicitly asks
  for amend
- **Does not create branches or PRs** — this repo commits directly to main
