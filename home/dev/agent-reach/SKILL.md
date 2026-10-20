---
name: agent-reach
description: >-
  通过本机 Nix 管理的 Agent Reach、OpenCLI 和 yt-dlp 搜索平台内内容、读取原帖或提取视频字幕。
  适用于小红书、B站、Reddit、Twitter/X 等平台的站内检索和原始内容读取，或用户明确要求使用这些工具时。
  普通网页、通用联网搜索及已有专用连接器的任务继续使用相应工具。
---

# Agent Reach：本机平台访问

## 本机范围

- Nix 管理 `agent-reach`、`opencli`、`mcporter` 和 `yt-dlp`；GitHub 使用已有的 `gh`。
- Exa 暂不启用。需要通用联网搜索时使用当前会话已有的搜索工具。
- 此处的 Skill 由 Home Manager 管理。安装或升级工具应修改 Nix 定义并验证，系统应用由用户手动执行。
  不运行上游的 `install --system`、`uninstall`、`skill install`，也不运行 pip/npm 全局安装或自更新。

## 选择工具

| 需求 | 工具 |
| --- | --- |
| 小红书、B站、Reddit、Twitter/X 等站内检索与内容 | OpenCLI 对应站点适配器 |
| YouTube 视频信息、已有字幕或自动字幕 | yt-dlp |
| GitHub 仓库、Issue、代码 | gh |
| 普通网页与全网搜索 | 会话已有的网页或搜索工具 |

首次使用某个 OpenCLI 站点前，先发现命令并读取该版本的帮助：

```bash
opencli list search --site bilibili
opencli bilibili search --help
```

按帮助选择参数，优先返回 JSON；记录原始链接，并以实际非空内容验收。
不要仅凭适配器列举结果推断平台已经可访问。

## 浏览器连接

OpenCLI 使用 Chrome 的 OpenCLI 扩展与本地桥接服务。首次需要浏览器渠道时运行
`opencli doctor` 检查连接；扩展需要用户在 Chrome 中手动安装。
需要登录的平台由用户在自己的 Chrome 会话完成登录，随后再执行所需的只读命令。
不要索取账号密码、把 Cookie 贴进对话，或把凭据写入 Nix/Git。

`agent-reach doctor --json` 可辅助判断工具状态，但有些渠道只检查本地配置或桥接连接。
未启用的渠道和 Exa 显示 off/warn 属于本机预期范围，不要为凑齐体检结果安装额外工具。
登录失效或页面要求验证时，交给用户在浏览器处理，再继续原任务。

## YouTube 字幕

```bash
yt-dlp --list-subs 'https://www.youtube.com/watch?v=VIDEO_ID'
yt-dlp --write-sub --write-auto-sub --skip-download -o '/tmp/%(id)s' 'https://www.youtube.com/watch?v=VIDEO_ID'
```

区分视频信息、已有字幕与音频转写：下载成功不代表拿到了字幕，没有字幕也不代表已经转写。
本机 yt-dlp 已由 Nixpkgs 配好 Deno，Agent Reach 包也能发现它，无需另写运行时配置。

## 操作边界

平台读取授权不包含发帖、评论、点赞、关注等写操作。只执行当前用户任务所需的命令；
临时输出放在独立临时目录，完成后按任务需要清理自己创建的浏览器会话或标签页。
