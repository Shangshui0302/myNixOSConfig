---
title: Orca 多代理工作台
category: 开发与工具
tags: [orca, ai, codex, antigravity, dsh, home-manager]
updated: 2026-10-20
---

# Orca 多代理工作台

本机使用 [stablyai/orca](https://github.com/stablyai/orca) v1.4.230，基础包来自固定 revision 的 [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix)。Home Manager 只消费其中的 Orca；其 nixpkgs 跟随本仓库，已有输入版本不变。GUI 命令为 `orca-ide`，原生管理 CLI 为 `orca-ide-cli`，社区包也提供 `orca` CLI；不要与 GNOME 同名屏幕阅读器混淆。

## 入口

应用菜单打开 Orca，或运行 `orca-ide`。Orca 默认终端使用已安装的 fish：本机 Bash 的 ble.sh 多行粘贴模式会拦住自动提交；此选择限于 Orca 的启动环境。可以添加已有本地文件夹，无需先建远程 GitHub 仓库。优先使用现有工程；不要为导入普通目录而初始化 Git、推送或复制历史。

首次 profile 默认只显示三种代理：

| Orca 代理 | 实际程序 | 数据归属 |
| --- | --- | --- |
| Codex（默认） | Home Manager 已有 `codex` | 既有 Codex 登录和会话 |
| Antigravity | 已有 `agy` 终端 | 既有 agy 登录和会话 |
| DSH | Nix 桥接到 Arch 容器的 `dsh-tui` | 共享 DSH_HOME；`dsh-tui` 目录别名指向原 `web` profile |

agy 的 Native Chat 是独立 ACP 服务及登录，不等于现有 agy CLI，因此此配置将 agy 保留为终端入口。Codex Native Chat 可按界面选择。终端参数默认不附加 YOLO；Codex Chat 权限为 `ask`。各 CLI 仍执行自己的权限确认。DSH TUI 提供 Pro / high / Manual 启动默认值，并用最终 profile overlay 覆盖 home 级配置默认值；TUI 已保存的模型与 effort 选择仍可能优先，启动后按界面核对。

DSH 桥固定使用容器 `/usr/bin/node` 与现有 `/usr/bin/dsh`，不会混入宿主机 Node；工作目录映射为 `/run/host` 下的同一目录。容器用户级 TUI 包固定为 `@deepseek-harness-tui/dsh-tui@0.16.1`，安装在 `~/distrobox/arch/.local/share/orca-dsh-tui`；它与现有 DSH 0.2.0-rc.2 配合。`~/.dsh/profiles/dsh-tui` 是指向同级 `web` 的目录别名；TUI 包通过 Web node_modules 的单独 module link 提供，原 Web manifest 和配置不改。桥接在启动时叠加 TUI 官方 patch 与 Nix 的 `orca-dsh/tui-overlay.yml`，因此使用原来的插件、配置和记忆存储，后续共享设置写入仍落在原 Web profile。原最小 TUI profile 已备份到 DSH_HOME/backups。Nix 管理宿主机桥接，容器依赖与目录别名属于容器可变状态。

## 会话与配置

Orca 新开终端不等于继续原有聊天。DSH 可用 `dsh-tui --resume <原ID>`；恢复要求同一 DSH_HOME 与原工作目录。恢复前核对原会话 ID、目录和占用状态；不要为了续聊而新建替代会话或合并其他聊天的绑定文件。

恢复中的 TUI 持有唯一写入权，同一会话的 Web/headless 写入需等它退出。Web 专属面板仍由 Web 前端渲染，不能把已加载 host 服务等同于全部面板有 TUI 界面。完整 Web 后端在同一进程保留，以支持 SSH、任务板、调度等插件；其 TUI 专用监听仅用 127.0.0.1 随机端口且不自动打开浏览器。

正常 Orca 会话与终端恢复保留；机器重启后恢复界面或滚动记录不自动证明 provider 对话已续上。派发工作前核对代理显示的 session。

首次启动关闭全局 agent hooks 安装和自动信任写入，避免覆盖既有 Codex、agy、DSH 配置。桌面入口明确使用现有 GNOME Secret Service 钥匙串，并补齐 Wayland 图形库加载路径。Nix 包另阻断 Orca 自动向真实 Codex home 回填会话的迁移，并禁用包内自更新。应用更新通过更新固定的社区 input 后重新构建完成。这些补丁绑定 v1.4.230 的唯一 anchor；升级不匹配会构建失败，需重新核查。

设置的默认值随包提供，仅应用于新 Orca profile；后续界面设置仍由 Orca 自己的 SQLite 状态保存，不将活动数据库纳入 Nix 管理。若在界面启用全局 hooks、自动信任或全权限，会产生新的配置写入或权限效果，应自行审阅。

## 构建与启用

```bash
nix build path:.#orca-ide
./result/bin/orca-ide
```

系统菜单、skills 和 Home Manager 包声明在 `home/dev/orca.nix`（由 `home/dev/ai.nix` 导入），由用户手动执行 `sudo nixos-rebuild switch --flake path:.` 后生效；构建或 dry-build 不等于已启用。

诊断可用 `orca-ide-cli status --json` 和 `orca-ide-cli terminal-daemon status --json`。本配置的 `ORCA_CLI_COMMAND` 明确指向同一包的 `orca-ide-cli`；调用技能时优先使用该入口。社区包的全局 `orca` 与 GNOME 屏幕阅读器存在名称冲突，若将来启用后者，应先调整命令暴露方式。

## Daemon、CLI 与 skills

Orca 自带终端 daemon，按同一个 profile 自动启动和接管；不另装第二份 orcad，也不额外启动争用同一 profile 的 headless 服务。GUI/runtime 就绪和 daemon 健康分别查看，关闭 GUI 后 daemon 仍可能保留原终端。升级时先确认旧 daemon 与会话的使用情况，再清理旧构建的保留根。

`local-deriv/orca-ide.nix` 仅对社区包追加本机默认配置、原有 ASAR 策略和 CLI 别名，社区维护基础来源、原生库、桌面文件和打包流程。`local-deriv/orca.nix` 组合 DSH 桥、fish、Wayland 和钥匙串参数。

两项官方 skill stub 由 `local-deriv/orca-skills.nix` 固定源 revision 与 SHA256，完整操作指南通过当前 CLI 的 `skills get` 动态读取。包版本变化会触发断言，要求同步核查技能来源。无需在宿主机运行 npx 安装器。

| 代理 | Home Manager 安装位置 |
| --- | --- |
| Codex | `~/.agents/skills/{orca-cli,orchestration}` |
| agy | `~/.gemini/config/skills/{orca-cli,orchestration}` 与 `~/.gemini/antigravity-cli/skills/{orca-cli,orchestration}` |
| DSH | `~/.dsh/skills/{orca-cli,orchestration}`，由容器原有 `.dsh` 目录链接共享 |

agy 1.3.5 自带指南与当前官网的全局路径存在分歧，因此只为这两个 skill 在两个位置建立同源链接，不替换其他技能目录。当前没有 `agy skills list` 子命令；文件部署不等于已经证明模型使用了技能。Codex 可在 `/skills` 查看；DSH 可用其已安装的文件 provider 枚举，或查看 TUI 技能菜单。Home Manager 尚未启用时，这些全局目录不会因为构建成功自动出现。

DSH 启动桥显式设置 `ORCA_CLI_COMMAND` 为该社区包的 CLI，并把 `ORCA_USER_DATA_PATH` 指向宿主机 Orca profile；不改变容器 HOME 或 DSH_HOME，不创建新会话。容器内可直接执行共享 Nix store 的 CLI，无需另装 Orca、MCP 或第二个 daemon。现有插件、认证、原 session ID 和历史继续保留。

## 相关链接

- [AI 与 VS Code 工具](vscode.md)
- [Distrobox](distrobox.md)
- [Nix 手工打包](nix-packaging.md)
- [Wiki 首页](../README.md)
