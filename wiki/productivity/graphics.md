---
title: 图像与视频工具
category: 生产力
tags: [gthumb, gimp, ffmpeg, kdenlive, glaxnimate, blender, image-editing, video-editing]
updated: 2026-09-02
---

# 图像与视频工具

仓库按使用深度提供图像、剪辑和动效工具：`gthumb` 负责日常图片处理，`gimp` 负责复杂修图，`kdenlive` 负责视频剪辑，`glaxnimate` 负责矢量动效，`blender` 用于 3D 和合成。它们都由 `home/productivity/graphics.nix` 安装。

## 选择哪个

| 工具 | 定位 | 适合的任务 |
|------|------|------------|
| gThumb | 轻量图片管理与快速编辑 | 裁剪、旋转、调整尺寸、批量浏览 |
| GIMP | 专业图像编辑器 | 图层合成、蒙版、选区、精细修图、导出控制 |
| FFmpeg | 命令行音视频工具 | 转码、抽帧、封装、音视频信息检查 |
| Kdenlive | 多轨视频剪辑 | 剪切、字幕、音频轨道、代理剪辑和最终导出 |
| Glaxnimate | 矢量动画 | 标注、图形转场和简单的 2D 动效 |
| Blender | 3D 与合成 | 3D 场景、摄像机跟踪和复杂合成 |
| Loupe | 图片查看器 | 快速打开和浏览图片，不承担完整编辑职责 |

如果只是把图片裁成指定尺寸，优先用 gThumb：打开图片后进入编辑、裁剪或调整尺寸，保存时选择覆盖或另存为即可，不需要手工处理选区和画布。Loupe 仍归媒体查看工具，配置在 `home/leisure/player.nix`。

## 日常工作流

1. 在文件管理器中双击图片，或从应用菜单打开 **gThumb**。
2. 用裁剪工具设定比例或直接输入目标尺寸。
3. 选择“另存为”保留原图；确认结果后再覆盖原文件。
4. 需要多图处理时使用 gThumb 的浏览/批量功能。

常用命令：

```bash
gthumb photo.jpg
gimp photo.jpg
```

## 专业编辑

GIMP 适合需要非破坏性步骤或精确控制的任务：

- 用图层拆分背景、文字和前景元素。
- 用蒙版隐藏内容，避免直接擦除原始像素。
- 用选区、路径和变换工具做局部处理与合成。
- 导出时按目标用途选择 PNG、JPEG 或其他格式，并检查尺寸与质量。

简单裁剪不必切换到 GIMP；当任务开始涉及多层内容、透明背景或精细修补时再使用它。

## 视频与动效工作流

Linux rice 演示建议使用 `OBS → Kdenlive → Glaxnimate`：OBS 录制桌面，Kdenlive 完成剪辑、双语字幕和配音对齐，Glaxnimate 补充界面标注与转场。只有需要 3D 片头、摄像机跟踪或复杂合成时再打开 Blender。

时间线卡顿时先在 Kdenlive 中启用代理/预览分辨率，最终渲染仍使用原始素材。当前机器使用 Radeon 780M 集成显卡，录制和剪辑先保持 2560×1600、30 fps；特效和 60 fps 片段按实际播放情况增加。

## 配置归属

| 配置 | 位置 |
|------|------|
| gThumb、GIMP、FFmpeg、Kdenlive、Glaxnimate、Blender | `home/productivity/graphics.nix` |
| Loupe | `home/leisure/player.nix` |
| Yazi 文件管理器 | `home/productivity/yazi.nix` |
| 文件管理器缩略图 | `home/productivity/files.nix` |

新增或调整包后，先检查 Nix 语法，再由用户手动执行：

```bash
nix-instantiate --parse home/productivity/graphics.nix
sudo nixos-rebuild switch --flake .
```

## 故障排查

- **应用菜单没有图像工具**：确认当前 Home Manager 配置导入了 `home/productivity/default.nix`。
- **Kdenlive 时间线播放不流畅**：为素材启用代理或降低预览分辨率，再进行最终渲染。
- **打开图片没有缩略图**：检查 [Yazi 文件管理器](yazi.md) 以及 `home/productivity/files.nix` 中的缩略图工具。
- **需要快速查看而不是编辑**：使用 Loupe，避免为简单查看启动 GIMP。

## 相关链接

- [Yazi 文件管理器](yazi.md) — 文件管理器操作与预览
- [媒体播放](../leisure/media.md) — Loupe 与其他媒体工具
- [办公软件套件](office.md)
- [约束与惯例](../constraints.md)
