---
title: Agent Orchestrator 与 Arch DSH
category: 开发与工具
tags: [ao, agents, dsh, distrobox, home-manager]
updated: 2026-10-23
---

# Agent Orchestrator 与 Arch DSH

[Agent Orchestrator](https://github.com/OrchestratorInc/agent-orchestrator)（AO）负责主代理派工、会话、开发看板与审查。桌面和 daemon 在 NixOS 宿主机运行；DSH 与 Node 使用现有 `arch` Distrobox 安装。容器名称是 `arch`，`arch-dbx` 是其主机名。

## 构建与试用

在包含本次配置的仓库或任务 worktree 中执行：

```bash
nix build path:.#agent-orchestrator-distrobox
./result/bin/agent-orchestrator
```

也可以直接 `nix run path:.#agent-orchestrator-distrobox`。这个入口带 DSH 桥接；`agent-orchestrator` 输出是未组合本机桥接的基础包。

全局应用菜单和 `ao` 命令由 `home/dev/agent-orchestrator.nix` 声明，经 `home/dev/ai.nix` 导入。构建不代表已经应用。需要安装到用户环境时，由用户手动执行：

```bash
sudo nixos-rebuild switch --flake path:.
```

软件更新由 Nix 包版本与下载哈希管理。不要使用 `ao start` 的下载路径或 npm 安装器替代此入口；启动桌面用 `agent-orchestrator`。

## 初次连接

1. 确认 `distrobox list` 中 `arch` 已存在，且容器 `/usr/bin/dsh` 可用。
2. 打开 AO，按界面加入一个小型 Git 项目，先验证日常开发流程。
3. 将需要使用 DSH 的角色选择为 DeepSeek Harness，使用 Chat 模式。
4. 模型与推理档位来自现有 DSH ACP profile；按界面返回的目录选择。
5. 主代理、worker 和 reviewer 可以使用不同 harness。DSH 没有专用 reviewer binding，审查角色选择其他受支持 harness。

AO 自带 DSH 管理安装的优先级高于 PATH。使用本机 Arch 安装时，不要再在 AO 中安装另一份 DSH；若已安装，先核对 AO 实际选中的可执行文件。

## 桥接的范围

| 项目 | 行为 |
| --- | --- |
| DSH 可执行文件 | 容器 `/usr/bin/node /usr/bin/dsh`，不使用宿主 Node |
| Chat | 原生 ACP profile，保留 stdin/stdout 通信，不分配 TTY |
| Terminal | headless profile 执行一次任务，不是 dsh-tui |
| DSH 配置 | 默认使用宿主 `~/.dsh`，可继承显式 `DSH_HOME` |
| 认证与历史 | 使用现有 DSH 数据；不复制登录凭据或修改 Web profile |
| 项目路径 | 使用宿主和容器都可访问的同一个绝对路径 |
| AO 回程 | 容器调用共享 Nix store 中的 `ao`，通过本机 daemon 通信 |
| 全局命令 | 仅安装 AO；专用 `dsh` 桥只进入 AO daemon 的 PATH |

桥接依赖此容器共享宿主 PID、网络和 Nix store。若以后改成隔离 PID 或网络的容器，需要重新验证回程，不能只看 DSH 能否启动。

AO 会恢复登录 Shell 的环境。桌面包装器通过受支持的 `AO_DAEMON_COMMAND` 在恢复之后设置专用 DSH PATH，确保选中本机的容器桥接。应用菜单与命令行使用同一个包装入口。

AO 不依赖 dsh-tui，无须安装该界面。桥接也不自动复用 Web 专属插件或任意自定义 profile，不额外扩大 DSH 工具权限；运行中的权限行为仍由对应 profile 与 AO 会话设置决定。

## 数据与隔离试用

AO 默认数据目录为 `~/.ao`。DSH 数据继续保留在现有 `DSH_HOME`，两者的会话标识各自管理。

需要独立的 AO 试用状态时，可以指定一个新目录：

```bash
env AO_DATA_DIR="$HOME/.local/state/ao-trial" ./result/bin/agent-orchestrator
```

包装入口将默认 `AO_RUN_FILE` 一并放进所选 `AO_DATA_DIR`。在终端检查该试用实例时也要使用相同的 `AO_DATA_DIR`。先关闭同一用户已经运行的 AO，再启动所选数据目录；否则单实例机制会把新启动交给原有窗口。

v0.14.5 的 Electron 配置目录由应用固定为 `~/.ao/electron`，会覆盖 `--user-data-dir` 参数。`AO_DATA_DIR` 只隔离 AO daemon 数据，不隔离桌面配置，也不隔离 DSH 凭据与历史。

## 故障排查

- **找不到 DSH**：先核对 `arch` 容器及 `/usr/bin/dsh`，再确认使用的是带 `-distrobox` 的 Nix 输出。终端单独运行全局 `dsh` 不能证明 AO 的私有桥已选中。
- **界面偏小**：本机包装入口检测到 Wayland 会话时使用原生 Wayland，让界面跟随桌面缩放。避免强制 XWayland；Hyprland 的 `force_zero_scaling` 会使该路径不跟随桌面比例。需要单独微调 AO 时，可用 `Ctrl+=` 放大、`Ctrl+-` 缩小、`Ctrl+0` 重置。
- **ACP 输出解析失败**：桥接不能向 stdout 输出欢迎信息，也不能分配终端；诊断内容应走 stderr。
- **项目目录不存在**：核对容器可访问该宿主绝对路径，包括 Git worktree 的 common repository；不要仅改 cwd 字符串而遗漏 Git 元数据路径。
- **AO 回程报告 daemon 不存在**：核对 `AO_DATA_DIR`、`AO_RUN_FILE`，以及容器是否仍共享宿主 PID/网络。
- **版本显示 dev**：上游 v0.14.5 桌面内的 Go CLI 构建未填写发布版本。桌面版本与固定下载来源为准，不能把 CLI 的 `dev` 输出当作安装了另一版本。
- **更新提示**：解包后的桌面没有 AppImage 自替换上下文，更新仍通过 Nix。上游界面可能继续展示新版本信息。

## 包装与验证边界

基础包固定官方 v0.14.5 x86_64 Linux AppImage，保留其 Electron、ASAR 与原生模块，修正 ELF 动态库路径。独立 ACP Node 使用锁定 nixpkgs 的 Node 22，避免原始 Node 在修改 ELF 后崩溃；这不替换 Electron 内部 Node。

包内还有一处绑定 v0.14.5 的启动修复：自定义 daemon 命令在打包桌面中改用真实 home 目录作为 cwd，避免上游把 `app.asar` 文件当目录而报 `ENOTDIR`。补丁校验唯一 anchor 与 ASAR 完整性；升级后不匹配时须重新核查。图形运行库包含已验证所需的 OpenGL 加载路径。

CLI 包装器显式提供 Git、OpenSSH 和 GitHub CLI，分别用于工作区操作、SSH remote 和未设置令牌时的 `gh auth token` 回退。基础桌面默认也通过该包装器启动 daemon；带 Distrobox 的入口在此基础上加入私有 DSH 桥接。这些宿主工具与容器内 DSH 的 PATH 分开管理。

桌面入口由 `makeDesktopItem` 生成，保留 `ao-app://` 协议及上游图标，并使用实测窗口类 `agent-orchestrator`。这样升级时不必依赖上游桌面文件的英文说明或分类字符串。此做法参考 [saavy1 的配方](https://github.com/saavy1/nixos-desktop/blob/fd317e312dfc17aebd37d96f64fd7468018430b5/packages/agent-orchestrator/default.nix)；显式命令依赖参考 [maxouverzou 的配方](https://github.com/maxouverzou/nixos-config/blob/7dd34e90652735661d54523f1dd10e3203b59f6c/packages/agent-orchestrator.nix)，并按 AO v0.14.5 源码核对。没有引入其 FHS 包装层、未证实需要的 `util-linux` 或禁用沙箱参数。

构建、CLI/daemon smoke test、ACP 握手与模型目录发现、真正模型任务和长期协作分别验收。没有发送模型任务的探测不能证明派工、代码修改和审查已经端到端通过。

## 相关链接

- [上游 v0.14.5](https://github.com/OrchestratorInc/agent-orchestrator/releases/tag/v0.14.5)
- [上游 DSH 适配说明](https://github.com/OrchestratorInc/agent-orchestrator/blob/v0.14.5/docs/harnesses/deepseek-harness.md)
- [Distrobox](distrobox.md)
- [Nix 手工打包](nix-packaging.md)
- [Wiki 首页](../README.md)
