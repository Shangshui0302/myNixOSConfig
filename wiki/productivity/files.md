---
title: 文件管理器与归档工具
category: 生产力
tags: [nautilus, dolphin, strata, file-manager, archive, matugen]
updated: 2026-10-02
---

# 文件管理器与归档工具

`home/productivity/files.nix` 提供三个图形文件管理器和一组归档/压缩工具。三个管理器同时保留，不互相接管默认目录关联。

## 文件管理器

| 程序 | 启动 | 说明 |
|------|------|------|
| Nautilus + Sushi | 应用菜单 / `nautilus` | 主 DE 与 GNOME 变体共用，Sushi 提供空格快速预览 |
| Dolphin | 应用菜单 / `dolphin` | KDE 文件管理器及其依赖 |
| Strata | 应用菜单 / `strata` | 键盘优先的 GTK4 文件管理器，本地包（源码构建） |

本仓库没有声明 `inode/directory` 的默认关联（`xdg.mimeApps` 只在 `home/dev/nvim.nix` 里为文本类型设置），三个管理器都不会自动成为默认目录处理程序；需要时手动指定：

```bash
xdg-mime default io.github.lgse.Strata.desktop inode/directory
```

## Strata

Strata 来自上游 `lgse/strata` v0.20.1，nixpkgs 没有，因此在 `local-deriv/strata.nix` 里从源码构建，打包细节见 [Nix 手工打包](../dev/nix-packaging.md)。

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

包装里带 `share/strata/install-source.toml`，声明该二进制由包管理器安装。因此 Settings → Updates 会显示「Installed by Nix as strata.」，并拒绝用应用内自更新覆盖 store 里的二进制；升级走 `flake.lock` 或修改 `local-deriv/strata.nix` 的 `version` 后由用户手动 rebuild。

### 主题与配色（Matugen）

Strata 用自绘主题：`src/style.css` 只引用自己的 `@theme_*` 变量、不引用系统 GTK/Adwaita 命名色，所以界面配色由它的主题文件决定，系统 GTK 主题只能影响少数未被覆盖的控件（tooltip、progressbar 等）。本仓库把壁纸取色接进来：

- **生成**：`home/theme/matugen/strata-theme.toml.tpl` → `~/.config/strata/themes/matugen.toml`。Strata 的自定义主题是**平铺单文件**（不是每个主题一个目录），**文件名 stem 就是主题 id**；文件是裸表，只有 `name` 与颜色键，缺必需键会被静默忽略。
- **选中**：`~/.config/strata/settings.toml` 的顶层 `theme = "matugen"` 与 `mode = "theme"`。该文件由 Strata 自己全量重写（任意偏好变更都重写整个文件），不能用 Home Manager 声明；`theme-apply` 每次把它重写成这两个固定值——文件不存在时创建只含这两行的最小文件，存在时只替换这两个顶层键（其余内容与权限保留；内容已一致就不写、也不记日志）。遇到它无法安全改写的畸形文件（BOM、缩进或带引号的键、缩进表头、多行字符串）会放弃改写并记 `stage=strata status=settings-assert-failed`，不会把文件改坏。由此有两条要记住：在 Settings → Appearance 里换成别的主题，下次 `theme-apply`（换壁纸、切模式或 rebuild）会把它改回 `matugen`；如果主题文件本身校验不过（缺必需键），Strata 会静默退回内置 `azure-glow`，而 `theme-apply` 不会有任何提示。`~/.config/strata/themes/matugen.toml` 这个文件名归 `theme-apply` 所有（自建主题请换名；`themes/` 下其它 `*.toml` 不受影响）。
- **深浅**：主题文件本身不分深浅，`theme-apply` 按 Darkman 当前模式把 light 或 dark 渲染结果复制到同一个 id。
- **生效时机**：Strata 只在启动时扫描主题目录、不监听文件变化，所以**换壁纸或切深浅之后要重开 Strata** 才会读到新配色；平时打开都是最新的。
- **换回内置主题**：Settings → Appearance → THEME LIBRARY 里选一个即可；下一次 `theme-apply`（换壁纸、切模式或 rebuild 激活）会把 `theme` 键断言回 `matugen`。
- 语法高亮色不写进模板：Strata 会从 `accent`/`text` 推导，而本机 Matugen 用 `scheme-content` + saturation 时 `secondary`/`tertiary` 常与 `primary` 收敛成同色，显式写反而更差。
- **标题栏开关的对比度**：侧栏开关是 `ToggleButton`，上游漏了它的 `:checked` 态样式，于是该状态由系统 GTK 主题填充强调色、而图标仍是 `@theme_accent`——M3 的浅色 `primary` 下两者几乎同色，图标会看不见。`local-deriv/strata-sidebar-toggle-checked.patch` 按上游自己的 checked 写法给该状态补了 0.22 alpha 的 accent 底色。

配色链路、缓存与排查见 [深色模式与动态配色](../desktop/darkmode.md)。

### NixOS 沙箱适配

Strata 把原生格式解析（图片、PDF、视频缩略图、压缩包、XLSX/DOCX、Mermaid/Math 渲染）放进 bubblewrap 沙箱，而沙箱参数在上游 `src/sandbox.rs` 里写死了 FHS 布局：只 bind `/usr`、`/lib`、`/lib64`、`/etc/fonts`，把沙箱内 `PATH` 设为 `/usr/bin`，并用 `/usr/bin/prlimit` 限制资源。纯文本/代码/Markdown 在主进程内解析，本来就不受影响。

NixOS 上这些前提不成立（`/usr/bin` 里只有 `env`，且沙箱看不到 `/nix/store`，helper 的 ELF 解释器无法 exec），因此本包带一个本地补丁 `local-deriv/strata-nixos-sandbox.patch`：追加只读 `/nix/store`、把沙箱内 `PATH`/`prlimit` 换成 store 路径、注入 GStreamer 插件目录，并把 `/usr` 改为可缺省 bind。打包细节见 [Nix 手工打包](../dev/nix-packaging.md)。

另需系统 profile 提供 `bwrap`：`trusted_command::resolve` 只查固定系统目录（`/run/current-system/sw/bin` 等）、不读 `PATH`，所以 [host/base/services.nix](../../host/base/services.nix) 把 `pkgs.bubblewrap` 放进了 `environment.systemPackages`。

升级 Strata 时要重新核对这个补丁；如果 patch 阶段冲突，构建会直接失败而不是静默退回。GUI 内的实际预览、媒体播放与 GVfs 访问以 switch 后的实测为准。

### 回退

从 `home/productivity/files.nix` 移除 `home.packages` 里的 `strata`（以及文件顶部的 `let` 绑定），然后由用户手动 rebuild：

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

- **Strata 预览报 `Unable to start the preview sandbox`**：系统 profile 里没有 `bwrap`（见上文，`host/base/services.nix` 负责提供）。
- **Strata 缩略图/PDF/压缩包预览空白**：先确认该版本的 `local-deriv/strata-nixos-sandbox.patch` 仍然生效（升级 Strata 后 patch 冲突会让构建直接失败，不会静默退回）；不要试图用 wrapper 的 `PATH` 修——沙箱内 `PATH` 由补丁注入的 store 路径决定。
- **应用菜单里没有 Strata 图标**：图标与 desktop entry 在 store 里，重新登录一次让桌面缓存刷新。
- **Yazi 没有缩略图**：见 [Yazi 文件管理器](yazi.md) 的排查节。

## 相关链接

- [Nix 手工打包](../dev/nix-packaging.md) — `local-deriv/strata.nix` 的构建与验证流程
- [Yazi 文件管理器](yazi.md) — 终端文件管理器
- [wiki 首页](../README.md)
