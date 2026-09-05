---
title: 约束与惯例
category: 顶层
tags: [constraints, conventions, nix]
updated: 2026-09-04
---

# NixOS Config — 约束与惯例

### 包分类标准

- 按主要用途单一归类：系统集成 `host/`，共享环境 `home/env/`，生产力 `home/productivity/`，开发 `home/dev/`，娱乐 `home/leisure/`，DE 专属放对应的 `host/de/`、`host/gnome/` 或 `home/de/`、`home/gnome.nix`。
- 支撑包跟随实际消费者；公共系统能力放 `host/`，用户应用放 `home/`，禁止重复声明。
- 新增包先检查已有声明和 nixpkgs；改动后同步导入关系与 Wiki 来源映射，并执行 parse 和 dry-build。
- 新增、升级、修复或审查 `local-deriv/` 包必须使用 `$nix-packaging`；NixOS、Home Manager、服务、部署和恢复任务使用 `$nixos-ecosystem`；每个手工包在 `flake.nix` 暴露同名 package output。
- 分类结构可按需要调整。现有目录无法合理容纳时，允许新增、删除、合并或重命名目录/模块，但必须同步迁移导入、文档和来源映射。

### Repo structure

```
flake.nix              # Entry point only — no inline package definitions
local-deriv/
  *.nix                # Custom packages and font derivations
  anthropic-fonts.nix  # Anthropic fonts
home/
  home.nix base.nix gnome.nix
  theme/ de/ env/ dev/ productivity/ leisure/  # Purpose-based subdirectories
host/
  base/ de/ gnome/     # base = shared; de = main-DE; gnome = GNOME variant
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

手工包同时提供独立构建入口；开发中的未跟踪文件使用 path flake：

```bash
nix build path:.#foo
```

**Never put new package definitions inside `nixpkgs.overlays` in `flake.nix`.**

---

### flake.nix

- `flake.nix` is an entry point and dependency manifest only
- No overlays currently in use; use `local-deriv/` for new packages and a local `overrideAttrs` for one-off fixes
- No inline derivations, no inline `mkDerivation`, no inline `appimageTools`

---

### Deduplication rules

- Network diagnostic tools (`dnsutils iputils tcpdump mtr nmap iperf3 ethtool iptables`)
  belong **only** in `host/network.nix` as `environment.systemPackages`
  → Do not add them to any `home/` module
- Font packages belong in `host/base/desktop.nix` as `fonts.packages` (shared by both DEs)
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

# Evaluate and independently build a local package
nix flake check path:. --no-build
nix build path:.#<pname> -L --no-link

# Full evaluation (catches type errors, missing args, bad imports)
cd ~/myNixOSConfig && nixos-rebuild dry-build --flake path:.
```

Parse passing does not guarantee evaluation success. Always run `dry-build` before
committing structural changes.

## 相关链接

- [Wiki 首页](README.md) — 各组件操作手册导航
- [Nix 手工打包](dev/nix-packaging.md) — `$nix-packaging`、本地派生和验证流程
- [Memory 决策记忆](../memory/INDEX.md) — 配置决策的背景与原因
