---
title: 媒体播放
category: 娱乐
tags: [mpv, modernz, matugen, media, pipewire, ani-cli, kazumi, go-musicfox, obs]
updated: 2026-11-20
---

# 媒体播放

用户级媒体环境：视频播放、音乐播放、动漫客户端与在线流媒体。媒体应用在 `home/leisure/player.nix` 安装；Yazi 的视频缩略图工具跟随 `home/productivity/files.nix`。音频与图形运行时由 `host/base/services.nix`（PipeWire）与 `host/base/hardware.nix`（amdgpu）支撑。

## 组件总览

```mermaid
graph TB
subgraph "用户层"
P["player.nix<br/>mpv + ModernZ, go-musicfox, ani-cli, kazumi"]
B["browser.nix<br/>Firefox, Google Chrome"]
end
subgraph "本地派生"
N["netease-cloud-music-web-player.nix<br/>Electron 包装"]
M["modernz.nix<br/>v0.3.3 数据/字体包"]
end
subgraph "系统服务"
S["services.nix<br/>PipeWire(Pulse/ALSA), pw-jack, 蓝牙, gvfs"]
H["hardware.nix<br/>amdgpu"]
end
P --> N
P --> M
B --> |"访问流媒体站点"| S
P --> |"音视频解码/缩略图"| S
N --> |"运行依赖"| H
```

`home/leisure/player.nix` 安装的应用：

| 应用 | 用途 |
| --- | --- |
| `gwenview` | 图片查看器；主桌面单独安装，NextKDE 由 Plasma 提供 |
| `mpv` + ModernZ | 通用视频/音频播放器；ModernZ 提供 Material 风格 OSC 控件 |
| `go-musicfox` | 终端网易云音乐播放器（附桌面入口 `foot -e musicfox`） |
| `obs-studio` | 直播与本地录制 |
| `ani-cli` | 命令行动漫搜索与播放，默认调用 mpv；使用 `ani-cli` 启动 |
| Kazumi | 图形化动漫聚合播放器，支持自定义规则、字幕与弹幕；由 nixpkgs 提供桌面入口 |
| 网易云网页版 | 本地派生 `local-deriv/netease-cloud-music-web-player.nix` Electron 打包 |

网易云网页版基于上游 1.6.1 的 `app.asar`，使用锁定的 nixpkgs Electron。构建时补上首次启动缺失的窗口缩放默认值，避免没有 `window-state.json` 时窗口初始化失败；不覆盖已有窗口状态。启动器保留 Electron 默认沙箱，不注入 `--no-sandbox` 或 `--disable-gpu-sandbox`。独立构建：`nix build .#netease-cloud-music-web-player --no-link -L`；构建和隔离启动检查不替代登录与实际播放验收。

启动器固定 `--password-store=kwallet6`，让网页会话的加密存储使用两个桌面共用的 KWallet。人脸登录后，首次访问钱包时输入一次钱包密码。锁定的 Electron 保留旧 `basic` 格式 Cookie 的读取兼容；新写入的加密数据依赖钱包密钥，之后切回 `basic` 不能保证读取。不要清空原应用目录或钱包来测试；应用配置后另行检查登录保持和播放。

主配置（Hyprland/niri）与 NextKDE 通过共享的 `home/leisure/player.nix` 安装 [KMusic](https://github.com/NextKde/KMusic)，从启动器打开 KMusic 或运行 `kmusic`。它是独立的 Qt Quick 音乐应用，支持本地音乐库、在线音源及账户功能；具体音源可用性由提供方决定。包定义在 `local-deriv/kmusic.nix`，源码固定到 `ad0222d4404a166a1607e2967f3201cea64111c5`，不运行上游可变安装器，不添加后台常驻服务。两个桌面共用同一包定义。

独立构建命令为 `nix build .#kmusic --no-link`。Nix 构建与辅助程序检查不能替代应用界面、账户登录或实际播放验收；这些需要应用配置后另行检查。

浏览器（Firefox、Google Chrome）在 `home/leisure/browser.nix`，用于访问 Netflix、YouTube、Bilibili 等在线流媒体。

Yazi 使用 `home/productivity/files.nix` 提供的 `ffmpegthumbnailer` 生成视频缩略图。

## 音频与硬件加速

- PipeWire 是统一音频后端，兼容 PulseAudio 与 ALSA；JACK 程序按需用 `pw-jack <程序>` 启动。蓝牙设备配对后可作为输出端。
- 视频解码依赖 amdgpu 驱动与 VA-API。mpv 中可启用 `hwdec=auto` 走 GPU 硬件解码，遇黑屏/卡顿再回退软件解码对比测试。
- 音效增强建议交由 PipeWire 插件（equalizer、spatializer）统一处理，关闭播放器内置音效以免冲突。

## mpv 个性化

`mpv` 使用 ModernZ 替换默认 OSC，配置由 Home Manager 写入；Lua、Material 图标字体和中文 locale 来自固定的 ModernZ release。

Matugen 会把当前壁纸生成的 Material 3 语义色写入 `~/.config/mpv/script-opts/modernz.conf`；mpv 始终使用生成的深色变体，避免桌面浅色模式下视频控件文字与画面对比不足：

- `primary`：播放进度、播放/暂停和悬停重点色。
- `surface_container`：控件/缩略图面板底色。
- `on_surface`：标题、时间和主要图标。
- `outline_variant`：边框和未播放进度。
- `layout=mini` + `seekbar_height=small`：最简控件布局与细进度条（ModernZ 上游没有 `minimal` 这个值）。

深浅色切换仍由 Darkman 驱动，但 mpv 固定读取深色 ModernZ 配置；壁纸变化会更新其 Material 3 重点色。mpv 已运行实例通常需要重新打开才能读取新 OSC 配置。

如需增加其他播放器选项，修改 `home/leisure/player.nix` 中的 `mpv.conf` 后手动 rebuild：

- `~/.config/mpv/mpv.conf`：由 Home Manager 生成，当前关闭默认 OSC 并关闭原生边框。
- `~/.config/mpv/script-opts/modernz.conf`：ModernZ 布局、按钮和颜色选项由主题链维护，不建议手动覆盖。
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
- **缩略图不显示**：Yazi 视频预览问题可检查 `home/productivity/files.nix` 提供的 `ffmpegthumbnailer`。
- **日志定位**：结合 PipeWire 日志与 mpv 日志排查。

## 相关链接

- [ModernZ](https://github.com/Samillion/ModernZ) — mpv OSC 上游项目
- [游戏平台](gaming.md) — 同属娱乐模块，共用 PipeWire/amdgpu
- [系统服务](../services.md) — PipeWire 音频栈与蓝牙
- [故障排除总览](../troubleshooting.md)
- memory：[ai-tools-source](../../memory/cards/ai-tools-source.md) — 本地派生包（AppImage/Electron）打包思路参考
