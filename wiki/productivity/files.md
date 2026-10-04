---
title: 文件管理器与归档工具
category: 生产力
tags: [nautilus, dolphin, strata, file-manager, archive, matugen]
updated: 2026-10-04
---

# 文件管理器与归档工具

`home/productivity/files.nix` 提供三个图形文件管理器和一组归档/压缩工具。主 DE 保留三个管理器，不声明 Strata 桌面集成；GNOME 使用 Nautilus。

## 目录

- [文件管理器](#文件管理器)
- [Strata](#strata)
- [桌面集成](#桌面集成)
- [普通偏好](#普通偏好)
- [归档与压缩工具](#归档与压缩工具)
- [故障排查](#故障排查)

## 文件管理器

| 程序 | 启动 | 说明 |
|------|------|------|
| Nautilus + Sushi | 应用菜单 / `nautilus` | 主 DE 与 GNOME 变体共用，Sushi 提供空格快速预览 |
| Dolphin | 应用菜单 / `dolphin` | KDE 文件管理器及其依赖 |
| Strata | 应用菜单 / `strata` | 主 DE 专用的 GTK4 文件管理器，来自固定提交的 nixpkgs fork |

主 DE 安装 Strata、Nautilus 和 Dolphin，不通过 Strata 专用模块设置默认目录程序。GNOME 变体不安装 Strata，使用自带 Nautilus。默认程序选择由桌面配置负责。

## Strata

Strata v0.21.0 通过临时 `strata-nixpkgs` flake input 获取，固定到 fork 的已验证提交 `e7095c7d23897f76fbdae73a819d8c79fd9e68d4`（[nixpkgs PR #570118](https://github.com/NixOS/nixpkgs/pull/570118)）。本仓库只消费该包；包定义和补丁在 nixpkgs 任务分支维护，不在 `local-deriv/` 保存副本。

```bash
strata                       # 打开家目录
strata ~/Documents           # 打开指定目录
strata --version             # 打印版本
```

常用按键（上游 README）：

| 按键 | 功能 |
|------|------|
| `Ctrl + K` | 递归搜索 |
| `Ctrl + L` | 输入路径或 URI |
| `Ctrl + F` | 过滤当前面板 |
| `Space` | 打开/关闭预览 |
| `F2` | 重命名 |
| `Alt + ←/→` | 历史前进/后退；`Alt + ↑` 进入上级 |
| `Ctrl + Z` / `Ctrl + Shift + Z` | 撤销/重做文件操作 |

`F1` 打开内置快捷键参考，底部 footer 可显示当前模式的提示。

### 更新方式

包装里带 `share/strata/install-source.toml`，声明该二进制由包管理器安装。因此 Settings → Updates 会显示「Installed by Nix as strata.」，并拒绝用应用内自更新覆盖 store 里的二进制；升级先在维护工作区完成打包和验证，再更新 `flake.nix` 中的固定提交与对应锁项，由用户手动 rebuild。系统自己的 `nixpkgs` input 不随该包改变；官方频道包含 Strata 后改用 `pkgs.strata`，移除临时 input。

### 桌面集成

本仓库只安装 Strata，不声明它的 FileChooser portal、默认目录 MIME 关联或 FileManager1 服务，也不提供 Strata 专用 HM 模块。安装包不会自动接管桌面入口；需要这些能力的用户可自行通过 NixOS/HM 原生选项配置。

应用自带的 setup 功能仍保留。其作用是在用户目录中生成集成配置；使用声明式配置时应在 Nix 中管理对应文件，避免再用应用按钮修改同一配置。

撤销此前的 HM 集成声明并应用配置后，原来的 HM 管理标记、portal 文件和 FileManager1 服务链接会被移除，MIME 配置不再声明 Strata 为默认目录程序。此前由应用 setup 生成的非 HM 文件不在本次撤销范围中。

旧版本的 `The Strata executable path must not be writable by other users` 来自对 sticky `/nix/store` 组写权限的误判。投稿包中的 `desktop.patch` 只对 root 所有、带 sticky bit、无 world-write 的 `/nix/store` 放行组写权限，仍检查其他祖先、包目录及可执行文件；同时修正包装程序路径与服务状态判断。补丁不包含 HM 私有标记或界面限制。

### 普通偏好

视图、排序、侧栏、点击行为和预览等偏好直接在 Strata 设置界面调整，由应用保存到 `~/.config/strata/settings.toml`。不提供 `programs.strata.settings` 或额外的 HM 覆盖文件。

撤销旧的 HM 偏好覆盖并应用配置后，Home Manager 会移除原来的覆盖文件链接；已有可写的 `settings.toml` 保留。重启 Strata 后使用其中的手动偏好。主题仍由本地 Matugen 链维护，详见下节。

`settings.toml` 由 Strata 全量重写，且拒绝替换符号链接，因此不要直接将它声明为 HM 只读文件。历史、缓存和会话状态也留给应用维护。

### 主题与配色（Matugen）

Strata 用自绘主题：`src/style.css` 只引用自己的 `@theme_*` 变量、不引用系统 GTK/Adwaita 命名色，所以界面配色由它的主题文件决定，系统 GTK 主题只能影响少数未被覆盖的控件（tooltip、progressbar 等）。本仓库把壁纸取色接进来：

- **生成**：`home/theme/matugen/strata-theme.toml.tpl` → `~/.config/strata/themes/matugen.toml`。Strata 的自定义主题是**平铺单文件**（不是每个主题一个目录），**文件名 stem 就是主题 id**；文件是裸表，只有 `name` 与颜色键，缺必需键会被静默忽略。
- **选中**：`~/.config/strata/settings.toml` 的顶层 `theme = "matugen"` 与 `mode = "theme"`。该文件由 Strata 自己全量重写（任意偏好变更都重写整个文件），不能用 Home Manager 声明；`theme-apply` 每次把它重写成这两个固定值——文件不存在时创建只含这两行的最小文件，存在时只替换这两个顶层键（其余内容与权限保留；内容已一致就不写、也不记日志）。遇到它无法安全改写的畸形文件（BOM、缩进或带引号的键、缩进表头、多行字符串）会放弃改写并记 `stage=strata status=settings-assert-failed`，不会把文件改坏。由此有两条要记住：在 Settings → Appearance 里换成别的主题，下次 `theme-apply`（换壁纸、切模式或 rebuild）会把它改回 `matugen`；如果主题文件本身校验不过（缺必需键），Strata 会静默退回内置 `azure-glow`，而 `theme-apply` 不会有任何提示。`~/.config/strata/themes/matugen.toml` 这个文件名归 `theme-apply` 所有（自建主题请换名；`themes/` 下其它 `*.toml` 不受影响）。
- **深浅**：主题文件本身不分深浅，`theme-apply` 按 Darkman 当前模式把 light 或 dark 渲染结果复制到同一个 id。
- **生效时机**：Strata 只在启动时扫描主题目录、不监听文件变化，所以**换壁纸或切深浅之后要重开 Strata** 才会读到新配色；平时打开都是最新的。
- **换回内置主题**：Settings → Appearance → THEME LIBRARY 里选一个即可；下一次 `theme-apply`（换壁纸、切模式或 rebuild 激活）会把 `theme` 键断言回 `matugen`。
- 语法高亮色不写进模板：Strata 会从 `accent`/`text` 推导，而本机 Matugen 用 `scheme-content` + saturation 时 `secondary`/`tertiary` 常与 `primary` 收敛成同色，显式写反而更差。
- **标题栏开关的对比度**：侧栏开关的选中态会渲染成浅色圆盘、里面的图标看不见。已知原因：`~/.config/gtk-4.0/gtk.css` 指向运行时 GTK 主题，GTK 以 **USER 优先级**加载它（高于应用的 APPLICATION），主题的 `button:checked/:active` 用 `--primary` 填成胶囊/圆盘；而 Strata 的标题栏图标是**按 accent 预渲染的纹理**（不吃 CSS `color`），M3 的 `primary` 又和 accent 同源同色，于是图标溶进填充。应用侧 CSS 赢不了（已实测，见 [打包笔记](../dev/nix-packaging.md)）。可行的三条路：把侧栏收起来（`Ctrl+B`，按钮回到深色底上就看得见）、改主题让 checked 填充不再用 `--primary`（桌面全局生效）、或等上游把该图标换成随状态翻转的颜色。

配色链路、缓存与排查见 [深色模式与动态配色](../desktop/darkmode.md)。

### NixOS 沙箱适配

独立包负责原生格式解析所需的 bubblewrap、Nix store 可见性、沙箱内工具路径、GStreamer 插件以及可信 helper 搜索路径。主机不再需要为 Strata 额外安装系统级 `bubblewrap`；桌面集成配置与 Matugen 主题仍由消费者决定。

这些补丁与完整构建、上游测试和预览验证记录在 `~/Projects/nixpkgs-maintain/development/strata/`。升级先在 nixpkgs 任务 worktree 中集中修改和验证；未改变的 derivation 可复用既有构建证据。系统 dry-build 只验证集成，实际 GUI、媒体播放与 GVfs 访问仍以用户应用后的实测为准。

### 回退

在 `home/productivity/files.nix` 移除 Strata 的条件包声明，然后由用户手动 rebuild；原有手动 `settings.toml` 留在原处：

```bash
cd ~/myNixOSConfig
sudo nixos-rebuild switch --flake .
```

## 归档与压缩工具

| 程序 | 用途 |
|------|------|
| `ouch` | 统一解压/压缩命令，Yazi 也复用 |
| `p7zip` / `unzip` | 7z、zip 归档 |
| `file-roller` | 图形归档管理器 |
| `rich-cli` | 终端富文本渲染（Yazi 富预览依赖） |
| `dragon-drop` | 拖拽文件到其他窗口 |
| `tumbler` | 缩略图服务（D-Bus） |
| `ffmpegthumbnailer` | 视频缩略图生成器，Yazi 也复用 |

## 故障排查

- **Strata 预览报 `Unable to start the preview sandbox`**：先确认实际运行的是固定 input 中的 0.21.0 包；该包自带可信 `bwrap` 搜索路径，再检查用户命名空间权限与应用日志。
- **Strata 缩略图/PDF/压缩包预览空白**：在 nixpkgs 任务 worktree 核对沙箱补丁及对应验证记录；沙箱内工具和 GStreamer 插件路径由包提供。
- **应用菜单里没有 Strata 图标**：图标与 desktop entry 在 store 里，重新登录一次让桌面缓存刷新。
- **Yazi 没有缩略图**：见 [Yazi 文件管理器](yazi.md) 的排查节。

## 相关链接

- [Nix 手工打包](../dev/nix-packaging.md) — 本地打包与投稿包消费的边界
- [Yazi 文件管理器](yazi.md) — 终端文件管理器
- [wiki 首页](../README.md)
