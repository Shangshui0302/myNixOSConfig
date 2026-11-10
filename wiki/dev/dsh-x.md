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
与 [agent-orchestrator.nix](../../local-deriv/agent-orchestrator.nix) 同一范式。运行时约定如下：

- **`/usr/bin/tar` 硬编码**：`shell/core-fetch.mjs` 的 `tarCommand()` 在非 Windows 分支
  返回字面量 `/usr/bin/tar`，NixOS 没有该路径，核心包解压会失败。用 `substituteInPlace`
  换成 `gnutar` 的 store 路径。
- **AppIndicator 兼容层**：AppImage 的 `usr/lib` 带 `libappindicator` / `libindicator` /
  `libgconf` / `libdbusmenu`，依赖 GTK2 的 `libgtk-x11-2.0.so.0` 等。Electron 44 完全不链接
  它们（`ldd` 主程序无相关项），用 `autoPatchelfIgnoreMissingDeps` 忽略。
- **pnpm 与 node 必须进 wrapper PATH**：`shell/env.mjs` 从用户 PATH 找 node，而
  `dsh plugin` 把参数转发给 pnpm 在 profile 目录内执行。AppImage 不自带 pnpm，
  所以 wrapper 里 `--prefix PATH` 补上专用 Node 24（含 npm/npx）与 `pnpm`。
  专用 Node 自身也将工具目录放到 PATH 前面，使生成的 dsh 命令行入口和 npm 生命周期
  脚本使用同一套工具，避免命中 `core/current/node` 中依赖 Electron 位置的旧 npm shim。
- **原生插件的 libstdc++**：部分下载到用户目录的原生插件没有自己的库搜索路径，
  主程序的 RUNPATH 不能传递给这些插件的依赖。缺失时启动会报
  `No usable native binding found for node-addon-require-builtin-linux-x64-gnu (auto)`
  （内层 cause 是 `libstdc++.so.6: cannot open shared object file`）。
  wrapper 通过 `LD_LIBRARY_PATH` 提供 `libstdc++`，由核心和子进程继承。
- **DSH 核心固定使用专用 Node 24**：wrapper 设置 `DSH_RUNTIME_NODE` 为 Nix 的绝对路径，
  外壳仍由 Electron 运行。该变量优先于启动器设置里的运行时选择；只把 node 放进 PATH
  不会改变核心默认使用 Electron 的行为。这样可避开
  [Electron 与 sharp 的 GLib 符号冲突](https://sharp.pixelplumbing.com/install/#electron-and-linux)。
  核心及其生成的 dsh 命令行入口跟随这个运行时。
- **登录自启与修复助手**：外壳加载核心时，在内存中将 Linux 自启和核心更新重启的目标
  改为 Nix 的 `bin/dsh-x` 包装器，并让诊断卸载助手使用专用 Node。
  登录自启通过 PATH 中的 `dsh-x` 跟随已应用的 Nix 版本，核心更新重启使用当前包装器的绝对路径。
  不修改 `~/.config/DSH/core/current` 内的文件。适配只针对已核对的调用点；核心结构变化时
  明确报错，提示更新 Nix 包，不将适配失败当作核心损坏来删除或回退。

[dsh-x-node.nix](../../local-deriv/dsh-x-node.nix) 固定封装 Node 官方 Linux x64 24.21.0
二进制及同一发布包中的 npm/npx，哈希与官方 `SHASUMS256.txt` 一致。DSH 的 `node-addon-require-builtin` 会探测
Node/V8 私有机器码布局；当前 Nixpkgs 的同版本构建未通过该插件的 getter 探测。
专用包保留官方符号，只修补解释器路径，通过 wrapper 提供 C++ 库；当前自动重写
RUNPATH 会导致这个非 PIE 二进制在加载器中崩溃。该运行时仅供 DSH-X 使用。

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
nix build path:.#dsh-x-node -L --no-link --print-out-paths
nix build path:.#mnemon -L --no-link --print-out-paths
nix flake check path:. --no-build
nixos-rebuild dry-build --flake path:.
```

`dsh-x --version` 可能触发核心下载，因此并非无副作用的版本检查；本次未运行该命令。
核心下载成功后，安装版使用 `~/.config/DSH/core/current`。

原生依赖验证应包含 sharp 的 PNG 编码、元数据读取、`node-pty` 的终端读写，以及
`node-addon-require-builtin` 的内部模块读取；
仅验证 `require('sharp')` 成功不足以排除后台线程崩溃。上述构建和 dry-build 不应用配置，
完整桌面与会话行为需在手动应用、彻底退出旧启动器并重新启动后确认。
还应检查 npm/npx 的版本，以及 `npm run` 中的 `node` 是否为同一专用运行时；
这与直接验证 Node 可启动是不同的调用路径。
`dsh-x` 构建时会运行入口适配测试，检查自启/重启的目标、卸载助手的运行时和参数，
以及适配失败时保留核心的行为。测试使用临时模块和模拟子进程，不执行真实卸载或更新。

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
| sharp 在图像元数据读取时崩溃 | 确认已使用修复后的包并彻底重启启动器；核心应由 Nix 的 `node` 运行，而非 `lib/dsh-x/DSH`；升级后重做原生 sharp 测试 |
| npm 报 `core/current/node/../../../DSH` 不存在 | 更新到包含 npm/npx 的专用运行时并重新启动 DSH-X；在 DSH 会话中检查 `command -v npm` 应指向专用包的 `bin/npm` |
| 提示「Nix 运行时适配失败」或核心与适配不兼容 | 保留现有核心和 profile，更新 DSH-X 的 Nix 包以匹配新核心；不要通过删除核心目录来重试 |
| 找不到语言服务器 | 确认新配置已应用，并从宿主终端检查对应命令是否在 PATH |

## 相关链接

- [Wiki 首页](../README.md)
- [Nix 手工打包](nix-packaging.md)
- [容器管理](distrobox.md)
- [包定义](../../local-deriv/dsh-x.nix)与 [Mnemon 后端](../../local-deriv/mnemon.nix)
- [AI 工具消费者](../../home/dev/ai.nix)与 [LSP 工具](../../home/dev/tools.nix)
