---
id: claude-code-version-strategy
type: decision
tags: [claude-code, ai, versioning, nixpkgs]
date: 2026-08-06
---

# claude-code 版本策略：默认 latest 跟随 nixpkgs

## 问题
之前 `home/dev/ai.nix` 里 claude-code 版本固定为 `2.1.156`，每次升级要手动查 nixpkgs 最新版本号 + 拉新 hash 改配置，维护繁琐。

## 决策
`ai.nix` 的 `claudeVersion` 支持两种取值：
- **`"latest"`（默认）**：直接用 `pkgs.claude-code`（nixpkgs 里的包），rebuild 时自动跟随 nixpkgs 最新版本
- **具体版本号**（如 `"2.1.222"`）：`overrideAttrs` + `claudeSrcs.${version}.hash` 指定版本

```nix
claudeVersion = "latest";  # 或 "2.1.222"（需 claudeSrcs 里有对应 hash）

claudePkg =
  if claudeVersion == "latest" then
    pkgs.claude-code
  else
    (pkgs.claude-code.overrideAttrs (_: {
      version = claudeVersion;
      src = pkgs.fetchurl {
        url = "https://downloads.claude.ai/claude-code-releases/${claudeVersion}/linux-x64/claude";
        hash = claudeSrcs.${claudeVersion}.hash;
      };
    }));
```

## Why
- 用户想要默认跟随最新版本，省去手动查版本号 + 拉 hash 的步骤
- 与"claude-code 全部走 nix 管理"原则一致（nixpkgs 更新 → rebuild → claude-code 更新）
- 保留 pin 具体版本的能力（claudeSrcs 里配 hash），应对需要稳定版本的场景

## How to apply
- 默认保持 `claudeVersion = "latest"`
- 需要固定版本时：改成具体版本号，并在 `claudeSrcs` 加对应 hash（从 nixpkgs `pkgs/by-name/cl/claude-code/manifest.json` 的 `platforms.linux-x64.checksum` 取 hex 转 SRI）
- 更新 nixpkgs 后 rebuild 即拿到新 claude-code

相关: [[ai-tools-source]] | [[nixos-system-management]]
