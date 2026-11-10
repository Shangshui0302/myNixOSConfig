---
title: DSH-X 桌面启动器
category: 开发与工具
tags: [dsh, electron, mnemon, lsp, nix]
updated: 2026-11-10
---

# DSH-X（DSH 桌面启动器）

DSH-X 为宿主 NixOS 提供一个可选启动入口；现有 Arch distrobox 入口保留。DSH-X 是社区维护的
Electron 启动器（[yyh-001/DSH-X](https://github.com/yyh-001/DSH-X)），负责版本安装、
启动项、插件与 MCP 管理；DSH 本体由它从 npm 拉到用户目录。

## 启动

手动应用包含本次改动的配置后，在应用启动器搜索 **DSH-X**，或运行 `dsh-x`。
首次获取核心需要网络；本仓库不自动启动应用，也不迁移现有 profile 的原生依赖。

## 宿主运行的边界

Nix store 只包含启动器；DSH 的 profile 和会话位于 `~/.dsh`（`DSH_HOME`），
启动器还会将核心安装到用户可写目录。这不保证容器安装的原生 Node 依赖能在宿主直接使用。
目前的工作环境约定仍是在 Arch 容器中运行 DSH；改用宿主之前应先确认共享 profile
的原生依赖兼容性，避免影响现有入口。

DSH-X 的默认目录与现有 profile 相关位置如下；共享目录不等于已验证可直接迁移：

| 项 | DSH-X 默认 | 来源 |
| --- | --- | --- |
| `DSH_HOME` | `~/.dsh` | `plugin-tool.js` 的 `process.env.DSH_HOME \|\| join(homedir(), '.dsh')` |
| `DSH_PROFILE` | `web` | 同上 |
| 核心目录 | `~/.config/DSH/core/current` | 安装版外壳的 `core/current` |
| 设置文件 | `~/.config/DSH/settings.json` | `shell/env.mjs` |

## 打包要点

[dsh-x.nix](../../local-deriv/dsh-x.nix) 走 `appimageTools.extract` + `autoPatchelfHook` + `makeWrapper`，
与 [agent-orchestrator.nix](../../local-deriv/agent-orchestrator.nix) 同一范式。四个非显然的处理：

- **`/usr/bin/tar` 硬编码**：`shell/core-fetch.mjs` 的 `tarCommand()` 在非 Windows 分支
  返回字面量 `/usr/bin/tar`，NixOS 没有该路径，核心包解压会失败。用 `substituteInPlace`
  换成 `gnutar` 的 store 路径。
- **AppIndicator 兼容层**：AppImage 的 `usr/lib` 带 `libappindicator` / `libindicator` /
  `libgconf` / `libdbusmenu`，依赖 GTK2 的 `libgtk-x11-2.0.so.0` 等。Electron 44 完全不链接
  它们（`ldd` 主程序无相关项），用 `autoPatchelfIgnoreMissingDeps` 忽略。
- **pnpm 与 node 必须进 wrapper PATH**：`shell/env.mjs` 从用户 PATH 找 node，而
  `dsh plugin` 把参数转发给 pnpm 在 profile 目录内执行。AppImage 不自带 pnpm，
  所以 wrapper 里 `--prefix PATH` 补上 `nodejs_24` 与 `pnpm`。
- **libstdc++ 必须进 `LD_LIBRARY_PATH`**：dsh 的原生插件（`node-addon-require-builtin`、
  `node-pty`、`@img/sharp`、`koffi`、`sherpa-onnx`）都 NEEDED `libstdc++.so.6`，
  而 Electron 二进制自身只链 `libgcc_s`，所以 `runtimeDependencies` 里加
  `stdenv.cc.cc.lib` 只让 RUNPATH 出现该路径——不够。`.node` 自身没有 RUNPATH，
  glibc 的 `dlopen` 只按主程序 RUNPATH 解析**主程序的直接依赖**，不递归到被 dlopen
  的对象。症状是启动时报
  `No usable native binding found for node-addon-require-builtin-linux-x64-gnu (auto)`
  （内层 cause 是 `libstdc++.so.6: cannot open shared object file`）。
  wrapper 里 `--prefix LD_LIBRARY_PATH` 才是有效修复。

`--unset APPIMAGE` / `--unset APPDIR` 让 electron-updater 的 AppImageUpdater 失效，
避免它试图替换 store 路径；核心层仍可经 npm 更新到可写的 `~/.config/DSH`。

## 配套改动

- [tools.nix](../../home/dev/tools.nix)：11 个 LSP 语言服务器（`bash-language-server`、`clang-tools`、
  `gopls`、`lua-language-server`、`nixd`、`pyright`、`rust-analyzer`、`taplo`、
  `typescript-language-server`、`vscode-json-languageserver`、`yaml-language-server`）。
  DSH 的 LSP 插件按裸命令名从 PATH 解析，原先由容器的 `/usr/sbin` 提供。
- [mnemon.nix](../../local-deriv/mnemon.nix)：`@mnemon-dev/mnemon` 是薄启动器，真正的后端是
  `@mnemon-dev/mnemon@<version>-linux-x64` 这个平台包里的静态 Go 二进制，
  必须解到启动器包内的 `node_modules/@mnemon-dev/mnemon-linux-x64` 才能被解析。
- 宿主运行时需核对 `~/.dsh/cordis.patch.yml` 中 `playwright-cdp` 的 `command`：
  若仍指向容器的 `/usr/sbin/node`，应使用宿主可解析的 `node`。
  这属于仓库外的运行环境配置，本次 Nix 改动不会自动修改它。

## 验证

```bash
nix build path:.#dsh-x -L --no-link --print-out-paths
nix build path:.#mnemon -L --no-link --print-out-paths
nix flake check path:. --no-build
nixos-rebuild dry-build --flake path:.
```

`dsh-x --version` 可能触发核心下载，因此并非无副作用的版本检查；本次未运行该命令。
核心下载成功后，安装版使用 `~/.config/DSH/core/current`。

## 与容器版的关系

宿主版与容器版共用 `~/.dsh`，**不能同时运行**（会争抢同一 profile 的端口与锁）。
迁移期保留容器作回退；本次改动不删除 `home/dev/containers.nix` 中的 Arch 配置。
共享状态目录不代表容器构建的原生 Node 依赖可直接在宿主使用；首次迁移前需单独验证兼容性。

## 故障排查

| 问题 | 检查方式 |
| --- | --- |
| 找不到启动器或 Mnemon | 确认已手动应用配置；先用上面的独立构建命令检查包 |
| 下载核心失败 | 检查网络与用户目录写权限；不要尝试写入 Nix store |
| 原生 Node 插件加载失败 | 核对插件二进制与宿主运行环境是否兼容，保留容器回退；不要同时启动同一 profile |
| 找不到语言服务器 | 确认新配置已应用，并从宿主终端检查对应命令是否在 PATH |

## 相关链接

- [Wiki 首页](../README.md)
- [Nix 手工打包](nix-packaging.md)
- [容器管理](distrobox.md)
- [包定义](../../local-deriv/dsh-x.nix)与 [Mnemon 后端](../../local-deriv/mnemon.nix)
- [AI 工具消费者](../../home/dev/ai.nix)与 [LSP 工具](../../home/dev/tools.nix)
