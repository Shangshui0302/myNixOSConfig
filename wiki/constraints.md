---
title: 约束与惯例
category: 顶层
tags: [constraints, conventions, nix]
updated: 2026-08-06
---

# NixOS Config — 约束与惯例

### Repo structure

```
flake.nix              # Entry point only — no inline package definitions
overlays/
  default.nix          # Imports all overlays as a list
  *.nix                # One overlay per file
local-deriv/
  *.nix                # Custom packages and font derivations
  anthropic-fonts.nix  # Anthropic fonts
home/
  default.nix git.nix theme.nix   # Root-level HM modules
  env/ dev/ productivity/ leisure/  # Purpose-based subdirectories
host/                  # NixOS system modules
assets/                # Binary assets (wallpapers, tarballs, etc.)
```

---

### Overlay vs override vs direct import

**Use `nixpkgs.overlays` only when:**
- Adding a name to an existing attrset that other modules reference via `pkgs.*`
  (e.g., `pkgs.vimPlugins.some-alias`)
- The modified package is depended on by other packages that must also see the new version

**Use `overrideAttrs` inline (no overlay) when:**
- Patching a package used in one place only
- The package has no reverse dependencies that need the change

**Use `local-deriv/*.nix` + direct import when:**
- Defining a brand-new package not in nixpkgs
- Pattern: `(import ../local-deriv/foo.nix { inherit pkgs; })`
- If the derivation needs a local `assets/` path, pass `src` as a parameter:
  ```nix
  # local-deriv/foo.nix
  { pkgs, src }: pkgs.stdenv.mkDerivation { inherit src; ... }
  # caller
  (import ../local-deriv/foo.nix { inherit pkgs; src = ../assets/foo.tar.gz; })
  ```

**Never put new package definitions inside `nixpkgs.overlays` in `flake.nix`.**

---

### flake.nix

- `flake.nix` is an entry point and dependency manifest only
- Overlays belong in `overlays/`, imported as `nixpkgs.overlays = import ./overlays`
- No inline derivations, no inline `mkDerivation`, no inline `appimageTools`

---

### Deduplication rules

- Network diagnostic tools (`dnsutils iputils tcpdump mtr nmap iperf3 ethtool iptables`)
  belong **only** in `host/network.nix` as `environment.systemPackages`
  → Do not add them to any `home/` module
- Font packages belong in `local-deriv/fonts.nix`, imported from `home/theme.nix`
- Do not split a single package's override across two modules
  (e.g., src in an overlay + flags in a home module — merge into one place)

---

### Chaining overrides

When a package needs multiple changes (e.g., new src + extra flags + desktop entry),
do all of it in one `overrideAttrs` call in the module that installs it.

If a `.desktop` entry is defined via `xdg.desktopEntries`, the `exec` line must NOT
repeat flags already applied by `wrapProgram` in `postInstall`.

---

### systemd user services

`programs.onedrive` (HM) manages config files only — it does NOT generate a systemd
user service. The manual `systemd.user.services.onedrive` block in
`home/env/onedrive.nix` is intentional and required. Do not remove it.

---

### Sudo rules

`host/users.nix` NOPASSWD rules for `nix`, `nixos-rebuild`, `tee`, `chmod`, `chown`,
`install`, `mv`, `cp`, `rm` are **deliberate** on this single-user laptop.
Do not remove or restrict them.

---

### Scope in package lists

Inside `home.packages = with pkgs; [ ... ]`, bare names (without `pkgs.` prefix)
resolve correctly even inside nested `let...in` expressions.
Both forms are acceptable; do not refactor for style consistency alone.

---

### Verification after changes

```bash
# Parse-check new/modified .nix files
nix-instantiate --parse <file>

# Full evaluation (catches type errors, missing args, bad imports)
cd ~/myNixOSConfig && sudo nixos-rebuild dry-build --flake .
```

Parse passing does not guarantee evaluation success. Always run `dry-build` before
committing structural changes.

## 相关链接

- [Wiki 首页](README.md) — 各组件操作手册导航
- [Memory 决策记忆](../memory/INDEX.md) — 配置决策的背景与原因
