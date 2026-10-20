---
title: 文件管理器与归档工具
category: 生产力
tags: [nautilus, dolphin, strata, file-manager, archive, matugen]
updated: 2026-10-20
---

# 文件管理器与归档工具

`home/productivity/files.nix` 提供三个图形文件管理器和一组归档/压缩工具。主 DE 默认使用 Strata，GNOME 变体默认使用 Nautilus。

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

主 DE 安装 Strata、Nautilus 和 Dolphin，默认使用 Strata；GNOME 变体不安装 Strata，继续使用 Nautilus。其他文件管理器仍可从应用菜单手动启动。

### 文件夹默认打开方式

使用系统默认打开方式的「打开文件夹」由目录 MIME 类型 `inode/directory` 选择默认程序。`host/base/desktop.nix` 使用 NixOS 原生 `xdg.mime.defaultApplications`，主 DE 设为 `io.github.lgse.Strata.desktop`，GNOME 变体设为 `org.gnome.Nautilus.desktop`；应用配置后生成 `/etc/xdg/mimeapps.list`。用户的 `~/.config/mimeapps.list` 保持可写，其他文件类型的默认程序沿用现状；已有用户级目录关联会优先于系统默认值。

应用配置后检查：

```bash
xdg-mime query default inode/directory
gio mime inode/directory
xdg-open ~/Documents
```

主 DE 前两项应显示 `io.github.lgse.Strata.desktop`，第三项应打开 Strata；GNOME 变体对应 Nautilus。部分应用的「在文件管理器中显示」会走独立的 `org.freedesktop.FileManager1` D-Bus 接口，主 DE 的用户级服务由 Home Manager 链接到 Strata 包提供的模板。MIME 查询正确只能证明默认关联，仍需在原应用中验证实际打开行为。

## Strata

Strata v1.0.0 通过临时 `strata-nixpkgs` flake input 获取，跟随 fork 的 `feature/strata` 分支（[nixpkgs PR #570118](https://github.com/NixOS/nixpkgs/pull/570118)）。`flake.lock` 记录当前提交 `e9b01117f28bcb546bea973820cf307fef1e1d6b`；以后运行 flake 更新时会获取该分支的最新提交，普通 rebuild 则沿用锁定版本。本仓库只消费该包；包定义和补丁在 nixpkgs 任务分支维护，不在 `local-deriv/` 保存副本。

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

包装里带 `share/strata/install-source.toml`，声明该二进制由包管理器安装。因此 Settings → Updates 会显示「Installed by Nix as strata.」，并拒绝用应用内自更新覆盖 store 里的二进制；升级先在维护工作区完成打包和验证并推送到 fork 的 `feature/strata`，再运行 `nix flake update strata-nixpkgs` 更新锁项，由用户手动 rebuild。运行不带 input 名称的 `nix flake update` 则刷新全部 inputs。系统自己的 `nixpkgs` input 不随该包改变；官方频道包含 Strata 后改用 `pkgs.strata`，移除临时 input。

### 桌面集成

主 DE 的文件夹默认打开、`Super + E`、Noctalia 启动器与 Dock 固定入口，以及 Caelestia 文件管理器入口均使用 Strata。GNOME 变体继续使用 Nautilus。

`home/productivity/files.nix` 使用 `xdg.dataFile` 管理 `~/.local/share/dbus-1/services/org.freedesktop.FileManager1.service`，直接引用 Strata 包中带绝对路径的模板，使「在文件管理器中显示」也能激活 Strata。若当前会话已有其他程序占用该 D-Bus 名称，重新登录后再验证。

FileChooser portal（打开/保存文件对话框）继续沿用桌面现有配置。应用自带的 setup 功能仍保留，但不要用它改写上述已由 Nix 管理的目录默认关联和 FileManager1 服务。

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

这些补丁与完整构建、上游测试和预览验证记录在 `~/Projects/nixpkgs-maintain/development/strata/`。升级先在该包开发目录集中修改和验证，再集成到 nixpkgs 投稿分支；未改变的 derivation 可复用既有构建证据。系统 dry-build 只验证集成，实际 GUI、媒体播放与 GVfs 访问仍以用户应用后的实测为准。

### 回退

要恢复 Nautilus，先把 `host/base/desktop.nix` 的主 DE 目录默认值改回 `org.gnome.Nautilus.desktop`，移除 `home/productivity/files.nix` 的 FileManager1 服务声明，并把主 DE 快捷键与面板入口改回 Nautilus。若同时卸载 Strata，再移除它的条件包声明；原有手动 `settings.toml` 留在原处。最后由用户手动应用：

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

- **应用打开文件夹却启动 VS Code**：先确认已应用配置，再查询 `xdg-mime query default inode/directory`；若仍不正确，检查 `~/.config/mimeapps.list` 或桌面专属 `*-mimeapps.list` 中是否有优先级更高的目录关联。
- **宿主默认值正确，Lutris/Bottles 仍打开 VS Code**：两者的 FHS 环境默认看不到系统的 `/etc/xdg`。`home/leisure/gaming.nix` 已补上整个目录的只读映射，兼容通用和桌面专属关联，同时保留用户关联的优先级；手动 rebuild 后完全退出并重新启动相应应用，再测试原入口。详见[游戏平台](../leisure/gaming.md#故障排查)。
- **默认关联是 Strata，但「在文件管理器中显示」仍打开别的程序**：该入口可能使用 FileManager1；确认上述用户级服务链接存在，重新登录释放旧服务的 D-Bus 名称后，再在原应用中测试。
- **Nautilus 打开很慢**：分别尝试 `xdg-open ~/Documents` 和 `nautilus ~/Documents`，区分默认关联调用与 Nautilus 自身启动；「在文件管理器中显示」还需检查 FileManager1 激活。用 `journalctl --user -b --grep='Nautilus|nautilus|FileManager1|portal'` 查看是否有激活超时，不能仅凭 MIME 默认值正确就认定延迟已解决。
- **Strata 预览报 `Unable to start the preview sandbox`**：先确认实际运行的是固定 input 中的 1.0.0 包；该包自带可信 `bwrap` 搜索路径，再检查用户命名空间权限与应用日志。
- **Strata 缩略图/PDF/压缩包预览空白**：在 nixpkgs 任务 worktree 核对沙箱补丁及对应验证记录；沙箱内工具和 GStreamer 插件路径由包提供。
- **应用菜单里没有 Strata 图标**：图标与 desktop entry 在 store 里，重新登录一次让桌面缓存刷新。
- **Yazi 没有缩略图**：见 [Yazi 文件管理器](yazi.md) 的排查节。

## 相关链接

- [XDG 默认应用规范](https://specifications.freedesktop.org/mime-apps/latest/default.html) — MIME 默认关联的选择规则
- [Nix 手工打包](../dev/nix-packaging.md) — 本地打包与投稿包消费的边界
- [Yazi 文件管理器](yazi.md) — 终端文件管理器
- [wiki 首页](../README.md)
