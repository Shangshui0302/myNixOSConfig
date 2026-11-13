---
title: Niri
category: desktop
tags: [wm, wayland, niri, scrolling-layout]
updated: 2026-11-13
---

# Niri 使用指南

Niri 是滚动平铺 Wayland 合成器（scrollable-tiling window layout），每个工作区中的窗口列沿水平方向滚动，工作区沿垂直方向排列。与 Hyprland 平级；greetd 菜单中的 `niri.desktop` 由原生 `niri-session` 启动，Hyprland 则使用 UWSM 会话入口。

## 启动与切换

```bash
# greetd 菜单中选择 Niri；手动启动时直接运行原生 session wrapper
niri-session

# 注销当前 compositor
systemctl --user stop niri.service
```

Hyprland ↔ niri 切换：注销当前 compositor 回到 greetd → 选择另一个 Wayland session；Hyprland 的手动入口仍是 `uwsm start hyprland`。

## 配置

配置由 Nix 生成（`home/de/niri.nix` → `~/.config/niri/config.kdl`），手动改会被 rebuild 覆盖（与 hyprland.lua 相同约定）。验证语法：`niri validate`。

要点：
- **显示器**：`output "eDP-1" { scale 1.5 }`（2K 屏，与 Hyprland 一致）
- **输入**：xkb `us` + `caps:escape`，触摸板 `natural-scroll`
- **圆角**：全局 `geometry-corner-radius 15` + `clip-to-geometry true`，focus-ring 跟随圆角（与 Hyprland `decoration.rounding = 15` 一致，都对 Caelestia 屏幕边框内圆角 25−10）
- **无 CSD**：`prefer-no-csd`，foot 等去掉标题栏，用 focus-ring 标焦点
- **桌面 Shell**：由 shell-switcher 在图形会话启动时恢复所选 Shell；不在 niri 配置中重复启动
- **X11 应用**：Home Manager 的 `xwaylandSatellitePackage` 安装 `xwayland-satellite`，由 niri 按需启动，支持微信等 X11 客户端。更新后重新登录 niri 会话；排障时先确认 `command -v xwayland-satellite` 可找到程序，再查看 `journalctl --user -u niri.service -b`。

## 键位（Mod = Super）

| 键位 | 功能 |
|------|------|
| Mod+W / E / B / N / O | foot / strata / chrome / nvim / obsidian |
| Mod+Shift+Space | DigUp 内容搜索（小面板浮动，大结果窗口平铺） |
| Mod+Space / C / Alt+K / Comma | 启动器 / 剪贴板 / 控制中心 / 设置（按当前 Shell 分发） |
| Mod+Shift+C / Shift+L | 删除剪贴板历史 / 锁屏；Noctalia 清空历史，Caelestia 选择条目删除 |
| Mod+D / A / Alt+L / Shift+W | Caelestia 的 dashboard / sidebar / session / 面板总开关；Noctalia 不响应 |
| Mod+G / Tab | niri 原生工作区总览 |
| Mod+Shift+D | Darkman 切换深浅模式 |
| Mod+Q / F / Shift+F / V / Shift+M | 关闭 / 全屏 / 最大化列 / 浮动 / 退出 |
| Mod+Ctrl+Shift+W | 切换列的标签式显示 |
| Mod+H/J/K/L 或方向键 | 聚焦相邻列或列内窗口 |
| Mod+Shift+方向键 | 移动列或列内窗口（左右移动整列） |
| Mod+Alt+方向键 | 左右交换窗口位置，上下移动列内窗口 |
| Mod+Ctrl+方向键 | 调整窗口宽度或高度，每次 50 像素 |
| Mod+1..0 | 切换到当前编号的工作区；再次按相同编号回到上一个工作区 |
| Mod+Shift+1..0 | 将当前窗口移到对应编号的工作区 |
| Mod+Ctrl+1..0 | 将窗口宽度设置为 10%..100% |
| Mod+滚轮 | 切换工作区 |
| Mod+Minus/Equal | 列宽 ±10%（Shift 为窗口高度） |
| Mod+R / Ctrl+Shift+R | 循环预设列宽 / 窗口高度 |
| Mod+Ctrl+F | 扩展列到可用宽度 |
| Mod+BracketLeft/Right | 将窗口并入或移出相邻列 |
| Mod+Ctrl+Comma / Period | 将窗口并入当前列 / 从当前列移出 |
| Mod+Shift+Slash | niri 原生快捷键帮助 |
| Print / Shift+Print / Mod+Shift+Print | 当前屏幕 / niri 原生区域截图 / 原生区域截图 |
| XF86 音量、亮度与媒体键 | 音量、亮度及播放控制 |

截图保存到 `~/Pictures/Screenshots/`，并复制到剪贴板；区域截图使用 niri 自带选择界面。

默认列宽为 67%，可循环预设 33%、50%、67%、81%、96%；单列始终居中，多列在溢出时居中。窗口聚焦时不透明度为 0.88，未聚焦时为 0.82；Polkit 使用 KDE 官方代理，按 `org.kde.polkit-kde-authentication-agent-1` 应用标识匹配，浮动且不透明度为 0.96；其外观沿用主桌面 Qt/Kirigami 主题，见[权限与安全](../services.md#权限与安全)。工作区保持动态，数字键索引当前显示器已有工作区的排列顺序，并非固定 ID。

窗口开启动画为 410ms、关闭为 149ms、移动及缩放为 479ms，使用接近 Hyprland 的原生贝塞尔曲线（关闭为线性）。横向视口滚动、工作区切换及总览保留 niri 默认弹簧，三指横向滚动、三指纵向切工作区、四指纵向总览均为原生手势。

## 配色（静态回退 + Matugen 动态）

niri 的 focus-ring 颜色分两层：

1. **静态回退色**：直接定义在 `config.kdl` 的 `layout.focus-ring` 中，保留原生成色板
2. **matugen 动态覆盖**：`~/.config/niri/wallpaper-colors.kdl`——切壁纸时 matugen 直接写该文件，niri 的 include 监视自动热载换色（active = primary，inactive = outline）

config.kdl 末尾 `include` wallpaper-colors.kdl，覆盖前面的静态回退值。改配色切壁纸即可，无需 rebuild。

> Noctalia 不再分发 niri 配色（`niri_colors` 模板已停用），切 Noctalia 主题不影响 niri focus-ring。

## 已知差异（vs Hyprland）

- **布局与尺寸记忆**：单列原生居中不等于 Hyprland 的单窗口 75% 宽高伪平铺；不额外模拟首列对齐、特殊工作区、token-monitor 跨窗口重开尺寸记忆，也不引入常驻脚本或自定义动画着色器。`Super+P`、`Super+S` 和触摸板切换键未迁移。
- **截图与帮助**：保留 niri 原生截图和快捷键帮助；区域截图不会进入 Swappy，快捷键帮助不依赖当前 Shell。Shell 独有面板仍只在对应 Shell 下有效。
- **Noctalia 模糊区域**：bar、dock、panel、attached-panel 和 OSD 使用 `xray false`，由 Noctalia 通过 `ext-background-effect` 提交精确区域；不要额外设置 `blur true`，否则客户端撤销区域时仍可能模糊整个 layer 矩形。当前 Noctalia 默认启用 bar/dock 的 `compositor_blur`，dock 自身动画也会更新区域。参见[上游 niri 配置说明](https://github.com/noctalia-dev/noctalia-shell/blob/490d327d7ecc2dc350649b78dca2143e93209f3d/docs/user/compositor-settings/niri.mdx#L185-L195)。
- **实时模糊的动画限制**：foot/Obsidian 仍使用强制实时模糊。niri 26.04 的 non-xray 模糊会在窗口开合及拖动平铺窗口期间暂时消失，[当前文档](https://niri-wm.github.io/niri/Window-Effects.html#non-xray-effects-experimental)仍列出此限制，上游重构任务 [#3834](https://github.com/niri-wm/niri/issues/3834) 截至 2026-11-03 尚未完成；不能据此断言所有 Shell 动画都存在同一限制。换成 xray 会改变为只采样壁纸，无法保留相同的背景窗口模糊效果。
- **focus-ring 颜色** 由 Matugen 动态覆盖，不是 Hyprland 的 border
- **epic-mouse sensitivity**：niri 无逐设备等价项，未迁移

## 相关链接

- [Hyprland](hyprland.md) — 主力合成器
- [Noctalia](noctalia.md) — 面板（niri 原生支持）
- [wiki 首页](../README.md)
