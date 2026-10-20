---
title: Agent Reach 与 OpenCLI
category: 开发与工具
tags: [ai, agent-reach, opencli, browser, yt-dlp, home-manager]
updated: 2026-10-19
---

# Agent Reach 与 OpenCLI

Agent Reach 检查平台工具并提供使用指引；OpenCLI 通过 Chrome 扩展访问站点内容，
yt-dlp 负责 YouTube 视频信息与字幕。本机由 Nix 安装这些工具，Exa 暂不启用。

## 已接入的工具

| 工具 | 用途 | 来源 |
| --- | --- | --- |
| `agent-reach` | 工具与渠道体检 | 固定上游提交的本地 Python 包 |
| `opencli` | 站内搜索、帖子内容与浏览器访问 | 本地 OpenCLI 2.0.0 包，含内建适配器 |
| `yt-dlp` | YouTube 信息、已有字幕和自动字幕 | 锁定的 Nixpkgs，由 Home Manager 原生模块启用 |
| `mcporter` | MCP 命令行客户端 | 锁定的 Nixpkgs；本次不添加服务配置 |
| `gh` | GitHub 仓库、Issue 与代码 | 沿用开发工具模块已有安装 |

Agent Reach 使用包含只读安装检查与凭据处理修复的固定提交；工具升级由 Nix 定义管理。
不要运行上游的自动安装器、自更新或卸载流程，也不需要 pip/npm 全局安装。

用户级 `agent-reach` Skill 由 Home Manager 注册，提供适合本机工具范围的只读平台流程。
Skill 文件应随 Nix 配置维护；不要再运行 `agent-reach skill install` 覆盖它。

## 构建与应用

在本仓库分别构建两个本地包：

```bash
nix build path:.#agent-reach -L --no-link --print-out-paths
nix build path:.#opencli -L --no-link --print-out-paths
```

构建只生成 Nix store 输出。系统检查与应用是两个独立步骤：

```bash
nixos-rebuild dry-build --flake path:.
# 用户决定应用时手动执行：
sudo nixos-rebuild switch --flake path:.
```

Codex 不自动执行 switch。应用后在终端检查版本，并在新会话确认 Skill 已被发现：

```bash
agent-reach --version
opencli --version
yt-dlp --version
mcporter --version
```

## 首次连接 Chrome

1. 在需要使用的 Chrome 配置中安装 [OpenCLI 扩展](https://chromewebstore.google.com/detail/opencli/ildkmabpimmkaediidaifkhjpohdnifk)。
2. 保持 Chrome 和扩展启用，运行 `opencli doctor` 检查本地桥接连接。
3. 在该 Chrome 会话中手动登录需要访问的平台。
4. 执行一项只读查询，确认取得目标站点的实际内容。

CLI 构建成功、适配器存在和扩展已连接，分别证明不同环节；平台可用性仍需实际查询验证。
本次 Nix 配置不自动安装浏览器扩展、不创建平台账号，也不导入 Cookie。

OpenCLI 的可变状态和本地兼容链接保存在用户的 `~/.opencli/`；
日常浏览器登录态继续由 Chrome 管理，凭据不得写入 Nix store 或提交到 Git。

## 发现与使用站点命令

先列出目标站点的能力，再查看具体命令的参数：

```bash
opencli list search --site bilibili
opencli bilibili search --help
opencli list search --site xiaohongshu
opencli xiaohongshu search --help
```

例如搜索 B站：

```bash
opencli bilibili search 'NixOS' -f json
```

不同站点、不同命令可能有自己的登录或页面要求，按当前版本帮助处理。
读取授权不包含发帖、评论、点赞、关注等写操作。

## YouTube 信息与字幕

先确认视频提供哪些字幕，再按需要提取；将 `VIDEO_ID` 替换为目标视频 ID：

```bash
yt-dlp --list-subs 'https://www.youtube.com/watch?v=VIDEO_ID'
yt-dlp --write-sub --write-auto-sub --skip-download -o '/tmp/%(id)s' 'https://www.youtube.com/watch?v=VIDEO_ID'
```

字幕提取与音频转写是不同功能。本次不配置 Groq/OpenAI 转写密钥，
没有字幕的视频不会自动变成可读文字稿。

Nixpkgs 的 yt-dlp 已带 Deno，Agent Reach 包也为体检提供其命令路径，
无需另外写 `--js-runtimes node` 配置或再安装一份运行时。

## 体检与故障排查

```bash
agent-reach doctor --json
opencli doctor
```

| 现象 | 处理 |
| --- | --- |
| Exa 显示 off/warn | 当前未配置，属于预期范围；通用搜索使用现有联网工具 |
| Twitter 等渠道显示未安装 | 本次没有安装所有单平台 CLI；按任务需要使用已接入的 OpenCLI 适配器 |
| OpenCLI 扩展未连接 | 确认扩展装在当前 Chrome 配置中、已启用且 Chrome 正在运行 |
| 平台要求登录或验证 | 用户在 Chrome 中处理，再重试原只读任务 |
| 命令存在但无实际内容 | 查看命令帮助，核对目标页面和账号权限；不要把能力列表当作可用证明 |
| Agent Reach 拒绝 mcporter 配置链接 | 其读取器拒绝符号链接；以后配置时可用 `MCPORTER_CONFIG` 指向 Nix 生成的真实文件。本次没有设置该变量或创建配置 |

Doctor 对部分渠道只检查工具、配置或桥接状态，不保证每个站点都已实时验证。
不需要为了让所有渠道变绿而安装额外工具、导入账号凭据或运行 `install --system`。

## 相关链接

- [AI 与 VS Code 工具](vscode.md)
- [Nix 手工打包](nix-packaging.md)
- [Wiki 首页](../README.md)
- [Agent Reach](https://github.com/Panniantong/Agent-Reach)
- [OpenCLI](https://github.com/jackwener/opencli)
