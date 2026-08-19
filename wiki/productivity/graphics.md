---
title: 图像工具
category: 生产力
tags: [gthumb, gimp, image-editing, graphics]
updated: 2026-08-19
---

# 图像工具

仓库按使用深度提供两层图像工具：`gthumb` 负责随用随开的日常处理，`gimp` 负责图层、蒙版和复杂修图。两者都由 `home/productivity/graphics.nix` 安装。

## 选择哪个

| 工具 | 定位 | 适合的任务 |
|------|------|------------|
| gThumb | 轻量图片管理与快速编辑 | 裁剪、旋转、调整尺寸、批量浏览 |
| GIMP | 专业图像编辑器 | 图层合成、蒙版、选区、精细修图、导出控制 |
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

## 配置归属

| 配置 | 位置 |
|------|------|
| gThumb、GIMP | `home/productivity/graphics.nix` |
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
- **打开图片没有缩略图**：检查 [Yazi 文件管理器](yazi.md) 以及 `home/productivity/files.nix` 中的缩略图工具。
- **需要快速查看而不是编辑**：使用 Loupe，避免为简单查看启动 GIMP。

## 相关链接

- [Yazi 文件管理器](yazi.md) — 文件管理器操作与预览
- [媒体播放](../leisure/media.md) — Loupe 与其他媒体工具
- [办公软件套件](office.md)
- [约束与惯例](../constraints.md)
