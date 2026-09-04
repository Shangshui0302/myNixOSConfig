---
title: 媒体播放
category: 娱乐
tags: [mpv, media, pipewire, animeko, ani-cli, kazumi, cliamp, go-musicfox, obs, loupe]
updated: 2026-09-04
---

# 媒体播放

用户级媒体环境：视频/图片查看、音乐播放、动漫客户端与在线流媒体。媒体应用在 `home/leisure/player.nix` 安装；文件管理器缩略图工具跟随 `home/productivity/files.nix`。音频与图形运行时由 `host/base/services.nix`（PipeWire）与 `host/base/hardware.nix`（amdgpu）支撑。

## 组件总览

```mermaid
graph TB
subgraph "用户层"
P["player.nix<br/>mpv, loupe, go-musicfox, animeko, ani-cli, kazumi, cliamp"]
B["browser.nix<br/>Firefox, Google Chrome"]
end
subgraph "本地派生"
A["animeko.nix<br/>AppImage 封装"]
N["netease-cloud-music-web-player.nix<br/>Electron 包装"]
C["cliamp.nix<br/>v2.0.1 release binary 包装"]
end
subgraph "系统服务"
S["services.nix<br/>PipeWire(Pulse/ALSA/JACK), 蓝牙, gvfs"]
H["hardware.nix<br/>amdgpu"]
end
P --> A
P --> N
P --> C
B --> |"访问流媒体站点"| S
P --> |"音视频解码/缩略图"| S
A --> |"运行依赖"| H
N --> |"运行依赖"| H
C --> |"ALSA + yt-dlp + ffmpeg"| S
```

`home/leisure/player.nix` 安装的应用：

| 应用 | 用途 |
| --- | --- |
| `mpv` | 通用视频/音频播放器 |
| `loupe` | GNOME 图片查看器 |
| `go-musicfox` | 终端网易云音乐播放器（附桌面入口 `foot -e musicfox`） |
| `obs-studio` | 直播与本地录制 |
| Animeko | 动漫播放器，`local-deriv/animeko.nix` 封装官方 v6.1.0 AppImage，并通过 JVM 参数匹配 GTK 的 2 倍 UI 缩放 |
| `ani-cli` | 命令行动漫搜索与播放，默认调用 mpv；使用 `ani-cli` 启动 |
| Kazumi | 图形化动漫聚合播放器，支持自定义规则、字幕与弹幕；由 nixpkgs 提供桌面入口 |
| `cliamp` | 复古 Winamp 风格终端音乐播放器；本地派生固定 v2.0.1 release binary，网易云播放依赖 `yt-dlp` 与 `ffmpeg` |
| 网易云网页版 | 本地派生 `local-deriv/netease-cloud-music-web-player.nix` Electron 打包 |

浏览器（Firefox、Google Chrome）在 `home/leisure/browser.nix`，用于访问 Netflix、YouTube、Bilibili 等在线流媒体。

### cliamp 网易云

`cliamp` 的网易云功能使用浏览器登录态，不保存独立账号密码。先在浏览器登录 `music.163.com`，然后运行配置向导并选择对应浏览器：

```bash
cliamp setup
cliamp --provider netease
```

向导会写入类似下面的配置；`cookies_from` 的值按实际浏览器填写：

```toml
[netease]
enabled = true
cookies_from = "chrome"
```

搜索和歌单由网易云接口提供，播放通过 `yt-dlp` 获取音频并由 `ffmpeg` 解码。歌曲是否可播仍受账号、地区和版权限制影响。

### cliamp 补全

包内同时提供 Fish 与 Bash 补全。Home Manager 会把它们显式链接到用户目录，避免 NixOS 固化 profile 后 Fish vendor 路径不可见：

- Fish：`~/.config/fish/completions/cliamp.fish`
- Bash：`~/.local/share/bash-completion/completions/cliamp`

应用新的 Home Manager 配置后重启 shell；若要单独检查上游生成器，可运行：

```bash
cliamp completion fish | fish -n
cliamp completion bash | bash -n
```

如果 `cliamp plugins <Tab>` 仍无候选，先确认上述两个文件存在，再执行 `exec fish` 或重新加载 Bash completion。

文件管理器的图片/视频缩略图由 `home/productivity/files.nix` 中的 `ffmpegthumbnailer` 与 `tumbler` 提供；它们属于文件管理支撑包，而不是播放器本身。

## 音频与硬件加速

- PipeWire 是统一音频后端，兼容 PulseAudio、ALSA 与 JACK；蓝牙设备配对后可作为输出端。开箱即用，无需额外配置。
- 视频解码依赖 amdgpu 驱动与 VA-API。mpv 中可启用 `hwdec=auto` 走 GPU 硬件解码，遇黑屏/卡顿再回退软件解码对比测试。
- 音效增强建议交由 PipeWire 插件（equalizer、spatializer）统一处理，关闭播放器内置音效以免冲突。

## mpv 个性化（按需扩展）

仓库只安装了 mpv 包，未提供 `mpv.conf`。如需精细控制，可在用户配置目录创建：

- `~/.config/mpv/mpv.conf`：设置硬件解码、渲染后端、字幕字体与样式。
- 字幕：与视频同名同目录放置即可自动加载，支持 SRT/ASS/SSA/VTT；多语言场景确保系统装有相应字体。
- 播放列表与时间戳书签：通过配置文件或命令行设定循环/随机模式。

## 流媒体

- 浏览器中启用硬件加速与 DRM 组件（如 Widevine），保证受版权保护内容顺畅播放。
- Wayland 下如需更好的窗口装饰与合成，可在浏览器启动参数中启用相应特性。

## 故障排查

- **无法播放/黑屏**：确认 amdgpu 驱动已加载；切换 mpv 渲染后端或禁用硬件解码对比。
- **无声或声音异常**：确认 PipeWire 正常运行并选对输出设备；检查音量/静音，必要时重启音频服务。
- **流媒体无法播放**：确认浏览器已启用硬件加速与 DRM；检查网络与地区限制。
- **ani-cli 找不到番剧或播放失败**：检查 AniDB/源站连通性；必要时直接运行 `ani-cli` 查看交互提示。
- **Kazumi 源失效**：在应用内检查并更新自定义规则；Linux 版本依赖 WebKitGTK，规则站点变化时可能需要等待规则更新。
- **cliamp 网易云登录失败**：确认浏览器已登录 `music.163.com`，并在 `cliamp setup` 中选择正确的浏览器；播放失败时检查账号、地区和歌曲版权状态。
- **缩略图不显示**：确认 `home/productivity/files.nix` 提供的 `ffmpegthumbnailer` 与 `tumbler` 已安装且正常工作。
- **日志定位**：结合 PipeWire 日志与 mpv 日志排查。

## 相关链接

- [游戏平台](gaming.md) — 同属娱乐模块，共用 PipeWire/amdgpu
- [系统服务](../services.md) — PipeWire 音频栈与蓝牙
- [故障排除总览](../troubleshooting.md)
- memory：[ai-tools-source](../../memory/cards/ai-tools-source.md) — 本地派生包（AppImage/Electron）打包思路参考
