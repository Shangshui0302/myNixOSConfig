# Reproducibility Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix hardcoded secrets, machine-specific paths, and documentation gaps identified in the reproducibility audit.

**Architecture:** Remove hardcoded secrets from system-level env vars and move them to fish shell sourcing from `/persist/secrets/`. Replace all hardcoded `/home/lishangshui/` paths with `config.home.homeDirectory`. Add new-machine deployment docs to README.

**Tech Stack:** Nix (NixOS + Home Manager), fish shell

---

### Task 1: Remove hardcoded secrets and LiteLLM URL from desktop.nix

**Files:**
- Modify: `host/desktop.nix:10-21`

- [ ] **Step 1: Remove ANTHROPIC_AUTH_TOKEN and ANTHROPIC_BASE_URL from environment.variables**

Replace lines 19-20 in `host/desktop.nix`:

```nix
# Before (remove these two lines):
    ANTHROPIC_BASE_URL = "http://127.0.0.1:4000";
    ANTHROPIC_AUTH_TOKEN = "030222";

# After — the block becomes:
  environment.variables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    NIXOS_OZONE_WL = "1";
    EDITOR = "nvim";
    SUDO_EDITOR = "nvim";
    STEAM_FORCE_DESKTOPUI_SCALING = "1.5";
  };
```

- [ ] **Step 2: Commit**

```bash
git add host/desktop.nix
git commit -m "fix: remove hardcoded ANTHROPIC_AUTH_TOKEN and ANTHROPIC_BASE_URL from env vars"
```

---

### Task 2: Add fish shell env sourcing from /persist/secrets/

**Files:**
- Modify: `home/shell.nix:262-282`

- [ ] **Step 1: Add env file sourcing to fish interactiveShellInit**

Replace the fish interactiveShellInit block (lines 264-281):

```nix
    interactiveShellInit = ''
      # 从 /persist/secrets/ 加载环境变量（如果存在）
      if test -f /persist/secrets/litellm.env
        source /persist/secrets/litellm.env
      end

      # zoxide
      zoxide init fish | source

      # 别名
      alias ls='eza --icons=auto'
      alias ll='eza -l --icons=auto'
      alias la='eza -la --icons=auto'
      alias lt='eza -T --icons=auto'
      alias cat='bat'
      alias grep='rg'
      alias find='fd'
      alias top='btop'
      alias tree='eza -T --icons=auto'

      # fish 问候
      set -g fish_greeting
    '';
```

Note: The `source` command in fish exports variables from the sourced file. This works because `/persist/secrets/litellm.env` contains `export KEY=VALUE` lines, and fish's `source` handles `export FOO=BAR` syntax via the bash compatibility layer. If the file uses `KEY=VALUE` (no export), use `set -gx KEY VALUE` syntax or `export` via fish's built-in handling.

Actually, since the litellm.env file likely uses `KEY=VALUE` format for systemd EnvironmentFile compatibility, use this instead:

```nix
    interactiveShellInit = ''
      # 从 /persist/secrets/ 加载环境变量（如果存在）
      if test -f /persist/secrets/litellm.env
        while read -l line
          if string match -qr '^\s*[A-Z_]+\s*=' -- "$line"
            set -l kv (string split -m 1 "=" -- "$line")
            set -gx $kv[1] (string trim -- $kv[2])
          end
        end < /persist/secrets/litellm.env
      end

      # zoxide
      zoxide init fish | source

      # 别名
      alias ls='eza --icons=auto'
      alias ll='eza -l --icons=auto'
      alias la='eza -la --icons=auto'
      alias lt='eza -T --icons=auto'
      alias cat='bat'
      alias grep='rg'
      alias find='fd'
      alias top='btop'
      alias tree='eza -T --icons=auto'

      # fish 问候
      set -g fish_greeting
    '';
```

This parses `KEY=VALUE` lines (the format systemd EnvironmentFile expects) and exports them as fish global variables. The regex skips comment lines and empty lines. It also works if the file doesn't exist — just skips silently.

- [ ] **Step 2: Commit**

```bash
git add home/shell.nix
git commit -m "feat: source /persist/secrets/litellm.env from fish shell if present"
```

---

### Task 3: Replace hardcoded /home/lishangshui/ paths in noctalia.nix

**Files:**
- Modify: `home/noctalia.nix:324,409,413,450`

- [ ] **Step 1: Replace avatarImage path (line 324)**

```
# Before:
        avatarImage = "/home/lishangshui/Pictures/ProfiePictures/yamadaRyou_glassesHeadsphone.jpg";
# After:
        avatarImage = "${config.home.homeDirectory}/Pictures/ProfiePictures/yamadaRyou_glassesHeadsphone.jpg";
```

- [ ] **Step 2: Replace wallpaper directory (line 409)**

```
# Before:
        directory = "/home/lishangshui/Pictures/Wallpapers";
# After:
        directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
```

- [ ] **Step 3: Replace monitor wallpaper directory (line 413)**

```
# Before:
            directory = "/home/lishangshui/Pictures/Wallpapers";
# After:
            directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
```

- [ ] **Step 4: Replace favorites wallpaper path (line 450)**

```
# Before:
            path = "/home/lishangshui/Pictures/Wallpapers/th.jpg";
# After:
            path = "${config.home.homeDirectory}/Pictures/Wallpapers/th.jpg";
```

- [ ] **Step 5: Update the function signature to take `config` parameter**

`home/noctalia.nix` line 1 currently is:
```nix
{ pkgs, inputs, ... }:
```

Change to:
```nix
{ config, pkgs, inputs, ... }:
```

- [ ] **Step 6: Commit**

```bash
git add home/noctalia.nix
git commit -m "fix: replace hardcoded /home/lishangshui paths with config.home.homeDirectory in noctalia.nix"
```

---

### Task 4: Replace hardcoded paths in hyprland.nix

**Files:**
- Modify: `home/hyprland.nix:18,176,177`

- [ ] **Step 1: Update function signature to take `config`**

`home/hyprland.nix` line 1 currently is:
```nix
{ pkgs, ... }:
```

Change to:
```nix
{ config, pkgs, ... }:
```

- [ ] **Step 2: Replace hve_watchdog.sh path (line 18)**

```
# Before:
        "/home/lishangshui/.cache/noctalia/HVE/hve_watchdog.sh"
# After:
        "${config.home.homeDirectory}/.cache/noctalia/HVE/hve_watchdog.sh"
```

- [ ] **Step 3: Replace noctalia-colors.conf path (line 176)**

```
# Before:
      source = /home/lishangshui/.config/hypr/noctalia/noctalia-colors.conf
# After:
      source = ${config.home.homeDirectory}/.config/hypr/noctalia/noctalia-colors.conf
```

- [ ] **Step 4: Replace overlay.conf path (line 177)**

```
# Before:
      source = /home/lishangshui/.cache/noctalia/HVE/overlay.conf
# After:
      source = ${config.home.homeDirectory}/.cache/noctalia/HVE/overlay.conf
```

- [ ] **Step 5: Commit**

```bash
git add home/hyprland.nix
git commit -m "fix: replace hardcoded /home/lishangshui paths with config.home.homeDirectory in hyprland.nix"
```

---

### Task 5: Update README.md with deployment documentation

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add deployment checklist and /persist/ documentation to README**

After the "注意事项" section (line 64), append:

```markdown

## 新机器首次部署

### 1. 生成硬件配置

```bash
nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix ~/myNixOSConfig/
```

### 2. 修改机器特定配置

| 文件 | 需要修改的内容 |
|------|---------------|
| `host/core.nix` | `networking.hostName`、`time.timeZone`、`i18n.defaultLocale` |
| `home/default.nix` | `home.username`、`home.homeDirectory` |
| `home/hyprland.nix` | `monitor` 显示器配置 |
| `flake.nix` | `nixosConfigurations.<hostname>`、`home-manager.users.<name>` |

### 3. 创建 /persist 分区和文件

mihomo 和 LiteLLM 依赖 `/persist/` 下的配置文件，首次部署需要手动创建：

```bash
# 创建目录
sudo mkdir -p /persist/mihomo /persist/secrets

# mihomo 代理配置（必需，否则 mihomo 服务启动失败）
sudo cp <your-mihomo-config.yaml> /persist/mihomo/config.yaml

# LiteLLM 环境变量（可选，仅当使用 LiteLLM 代理时需要）
sudo cp <your-litellm.env> /persist/secrets/litellm.env
```

`/persist/secrets/litellm.env` 格式（`KEY=VALUE`）：
```
ANTHROPIC_AUTH_TOKEN=your-token
ANTHROPIC_BASE_URL=http://127.0.0.1:4000
DEEPSEEK_API_KEY=your-deepseek-key
LITELLM_MASTER_KEY=your-litellm-master-key
```

### 4. 用户文件和缓存

以下文件路径使用 `config.home.homeDirectory` 动态解析，但文件本身需要存在：

| 文件 | 用途 | 缺失时影响 |
|------|------|-----------|
| `~/Pictures/ProfiePictures/` | Noctalia 头像 | 头像不显示 |
| `~/Pictures/Wallpapers/` | Noctalia 壁纸 | 壁纸功能不可用 |
| `~/.cache/noctalia/HVE/` | Noctalia HVE 配置 | Hyprland 装饰配置缺失 |
| `~/.config/hypr/noctalia/` | Noctalia 颜色配置 | Hyprland 颜色回退到默认 |

首次启动 Noctalia 后，缓存文件会自动生成。

### 5. 应用配置

```bash
sudo nixos-rebuild switch --flake ~/myNixOSConfig#
```

### 6. 首次认证

- **OneDrive**: 终端运行 `onedrive` 完成 OAuth 认证
- **mihomo**: 确保 `/persist/mihomo/config.yaml` 中的订阅链接有效
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add new-machine deployment guide and /persist/ file requirements"
```

---

### Task 6: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Add env var sourcing note to CLAUDE.md**

After the "注意事项" section line (the last section), change the secrets line from:
```
- secrets 放 `/persist/secrets/`（如 `litellm.env`, `gh.env`），不进 git
```

To reflect the current mechanism — the line in CLAUDE.md already exists. Just update it to note the fish sourcing:

The CLAUDE.md currently has in README section (imported from README). Actually, CLAUDE.md already has a secrets note. Let me read CLAUDE.md more carefully.

Looking at the CLAUDE.md content from the system reminder:
```
- secrets 放 `/persist/secrets/`（如 `litellm.env`, `gh.env`），不进 git
```

This is already correct. The change is that `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_BASE_URL` are now loaded from fish shell sourcing `/persist/secrets/litellm.env` instead of being hardcoded in desktop.nix. Let me add a note about this.

In CLAUDE.md, the "注意事项" section reads:
```
- **查包强制多路径**...
- **每次改动后必须**...
- 修改后**不要自动 rebuild**...
- 修改 Hyprland 配置后必须...
- 优先用 Home Manager 管用户级配置...
- 涉及 overlay 或 unstable channel 的包，说明原因
- secrets 放 `/persist/secrets/`（如 `litellm.env`, `gh.env`），不进 git
- sudo 已配 NOPASSWD...
- 硬件相关...
- 2K 显示屏...
- **所有改动必须通过 nixos-rebuild 应用...**
```

I should update the line about `ANTHROPIC_BASE_URL` — it's no longer hardcoded. Also, I should note that fish shell sources `/persist/secrets/litellm.env` for API keys.

Actually, let me keep CLAUDE.md changes minimal. Just add a line about where API env vars come from now.

Wait, I don't see this being critical. The CLAUDE.md is about how Claude Code should behave, not a full system doc. The README changes cover the documentation. Let me skip the CLAUDE.md change since the existing line about secrets already covers it, and the mechanism change is an implementation detail.

Actually, let me reconsider. The CLAUDE.md says:
```
- **每次改动后必须**：更新 README.md 和 CLAUDE.md 反映变更 → commit → rebuild，但不 push
```

So I must update CLAUDE.md to reflect the changes. Let me add a note about the new env var mechanism.

Let me simplify — just update the existing secrets line to note the fish sourcing mechanism.

- [ ] **Step 1: Update CLAUDE.md to document the env var mechanism**

In CLAUDE.md, change:
```
- secrets 放 `/persist/secrets/`（如 `litellm.env`, `gh.env`），不进 git
```
To:
```
- secrets 放 `/persist/secrets/`（如 `litellm.env`），不进 git；fish shell 启动时自动 source
- API 密钥（ANTHROPIC_AUTH_TOKEN 等）通过 `/persist/secrets/litellm.env` 注入，不在 nix 配置中硬编码
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md with env var sourcing mechanism"
```
