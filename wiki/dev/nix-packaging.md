---
title: Nix 手工打包
category: 开发与工具
tags: [nix, packaging, local-deriv, development]
updated: 2026-09-30
---
# Nix 手工打包

本仓库用 `local-deriv/` 维护尚未进入 nixpkgs、需要固定版本或需要本机集成的包。以后新增、升级、修复或审查这些包，必须调用 `$nix-packaging` skill；不要直接凭经验写 derivation。

## 目录

- [核心流程](#核心流程)
- [流程新鲜度](#流程新鲜度)
- [开始一次打包](#开始一次打包)
- [进入打包环境](#进入打包环境)
- [选择打包方式](#选择打包方式)
- [Derivation 规范](#derivation-规范)
- [获取和更新哈希](#获取和更新哈希)
- [验证](#验证)
- [当前本地包](#当前本地包)
- [更新已有包](#更新已有包)
- [故障排查](#故障排查)

## 核心流程

```text
查仓库与 nixpkgs
  → 核对锁定接口与最新官方文档
  → 调查上游源码、release、CI 与许可证
  → 提交“问题 → 分析 → 解决”并确认
  → 选择原生 builder 或最小 wrapper
  → 独立构建和检查产物
  → 集成 dry-build
  → 用户手动 switch 并验证运行时
```

构建成功、产物 smoke test、NixOS dry-build 和已部署运行是四种不同状态，报告时必须分开。

## 流程新鲜度

`$nix-packaging` 不是一份冻结的打包口诀。每次执行都必须先记录 `flake.lock` 中的 nixpkgs revision，检查本次使用的 builder/helper 在锁定源码中的真实接口，并与当前官方 Nixpkgs Reference Manual 和 nix.dev 打包教程对照。

锁定源码决定当前仓库能使用什么，最新官方文档用于发现弃用、替代接口和流程变化。若两者不一致，Agent 必须先报告差异与迁移影响，再决定保持兼容或随 flake 升级迁移；不能静默混用。稳定变化确认后，应在同一份受审查的改动中同步 skill、引用资料和本手册并重新验证。

这是一道调用时门禁，不是后台自动更新器。skill 不会自行改写，也不会在无人审查时更新仓库；周期性巡检只有在明确需要后再单独增加。

## 开始一次打包

在 Codex 中明确调用 skill，并给出软件名称或官方地址：

```text
$nix-packaging 打包 <软件名或上游 URL>
```

更新或修复已有包时说明目标：

```text
$nix-packaging 将 modernz-mpv 更新到 0.4.0
$nix-packaging 将 animeko 从 AppImage 迁移到 v6.1.0 源码构建并修复 JCEF 启动
```

skill 会先只读调查并提交方案。非小型改动需要回复“确认”或“进行实施”后才会写文件。

## 进入打包环境

仓库提供锁定到当前 `flake.lock` 的工具环境，不需要把辅助工具永久安装进系统：

```bash
cd ~/myNixOSConfig
nix develop .#packaging
```

其中包含：

| 工具                                   | 用途                                    |
| -------------------------------------- | --------------------------------------- |
| `nix-init`                           | 生成可供人工修正的初始 derivation       |
| `nurl`                               | 根据 URL 生成 fetcher 与哈希            |
| `nix-update`                         | 辅助更新版本和依赖哈希                  |
| `nixfmt`、`statix`、`deadnix`    | 格式化与静态检查                        |
| `readelf`、`patchelf`、`file`    | 诊断预编译 ELF                          |
| `desktop-file-validate`、`fc-scan` | 分别校验 GUI desktop entry 与字体元数据 |

这些工具是加速器，不是真相源。生成结果必须对照上游和当前 nixpkgs 手工复核。

## 选择打包方式

| 上游形态       | 首选方式                                   | 典型检查                               |
| -------------- | ------------------------------------------ | -------------------------------------- |
| 标准源码项目   | 对应语言 builder 或`stdenv.mkDerivation` | 上游构建命令、测试、安装路径           |
| 预编译 ELF     | `autoPatchelfHook` + 最小 wrapper        | ELF interpreter、NEEDED、运行时命令    |
| AppImage       | `appimageTools.wrapType1/2`              | 内置库、desktop、icon、真实可执行名    |
| Electron/ASAR  | nixpkgs Electron 或 Node builder           | desktop、icon、Wayland 和 keyring 参数 |
| 字体/主题/数据 | `stdenvNoCC.mkDerivation`                | 标准输出目录与文件权限                 |
| Hyprland 插件  | `hyprlandPlugins.mkHyprlandPlugin`       | 当前 Hyprland ABI 与`.so` 路径       |

源码能够合理构建时优先源码。AppImage 和预编译二进制用于源码不可用或维护成本明显过高的情况，不是默认捷径。

## Derivation 规范

- 文件名使用 `local-deriv/<pname>.nix`；复杂源码包可沿用 nixpkgs 的 `callPackage` 参数集，简单包再使用 `{ pkgs, ... }:`。
- 消费者优先使用 `pkgs.callPackage`；单点修改使用 `overrideAttrs`，不为一个包创建 overlay。
- 使用 `pname`、`version`、固定 release/tag/commit 和 SRI `hash = "sha256-..."`。
- URL、tag 与文件名里的版本优先引用 `${version}`。
- 构建工具和 setup hooks 放 `nativeBuildInputs`；链接或运行库放 `buildInputs`。
- 运行时通过命令名调用的程序使用 store path 或 wrapper 提供 `PATH`。
- Go 源码包优先使用 `buildGoModule` 并固定 `vendorHash`；仅封装原生发布二进制时标注 `sourceProvenance` 为 `binaryNativeCode`。
- 优先默认 phases 或 `pre/post*`；完整覆盖 phase 时保留 `runHook preX/postX`。
- `meta` 从上游核对 `description`、`homepage`、`license`、`mainProgram`、`platforms`。
- 上游未发布许可证的字体或素材不能标成自由许可证；使用 `licenses.unfree` 并在文档中保留分发风险说明。
- 普通 build phase 禁止联网下载 Cargo、npm 或 Python 依赖。
- GUI 包不能只交付命令，必须处理 desktop entry、图标与 `Exec`。

每个手工包都要在 `flake.nix` 暴露同名构建目标：

```bash
nix build path:.#<pname>
```

开发中的新文件可能尚未被 Git 跟踪，因此使用 `path:.`。不要为了让 flake 看见文件而擅自 `git add`。

## 获取和更新哈希

优先使用与 fetcher 匹配的工具：

```bash
nurl <上游 URL>
```

无法直接预取时，把对应哈希暂设为 `pkgs.lib.fakeHash`，运行目标构建，再复制 mismatch 输出中的真实 SRI hash。改变 URL、`rev`、解包方式或依赖锁文件时必须重新计算对应哈希。

Rust 的 `cargoHash`、Go 的 `vendorHash`、npm 的 `npmDepsHash` 等是独立哈希，不能只更新 `src.hash`。

## 验证

先做语法和 flake 求值：

```bash
nix-instantiate --parse local-deriv/<pname>.nix
nix flake check path:. --no-build
```

再独立构建并保留日志：

```bash
nix build path:.#<pname> -L --no-link --print-out-paths
nix log path:.#<pname>
```

根据类型检查输出：CLI 跑安全的 `--version` 或 `--help`；ELF 检查动态依赖；GUI 检查 wrapper、desktop 和 icon；字体用 `fc-scan`；插件确认 `.so`。GUI 与字体包还可运行 `desktop-file-validate "$out/share/applications/<pname>.desktop"` 与 `fc-scan --format '%{family}\n' "$out"/share/fonts/truetype/*.ttf`。不能安全启动的 GUI 或守护进程应记录为“待 switch 后人工验证”。

最后验证系统集成：

```bash
git diff --check
nixos-rebuild dry-build --flake path:.
```

Codex 不自动应用配置。检查通过后由用户执行：

```bash
cd ~/myNixOSConfig
sudo nixos-rebuild switch --flake .
```

## 当前本地包

### ModernZ (`local-deriv/modernz.nix`)

ModernZ v0.3.3 是 mpv 的 OSC 界面，当前以 `stdenvNoCC` 数据包集成，不在构建阶段联网或编译：

- 上游：固定 GitHub release `Samillion/ModernZ` `v0.3.3`，许可证为 LGPL-2.1-only。
- flake 入口：`nix build path:.#modernz-mpv`。
- 输出：`share/mpv/scripts/modernz.lua`、`share/mpv/script-opts/modernz-locale.json`、`share/fonts/modernz-icons.ttf` 和许可证文件。
- 消费者：`home/leisure/player.nix` 将脚本、locale 和字体发布到 mpv 配置目录；Matugen 另行生成 ModernZ OSC 配置。

验证包本身和系统集成时分别运行：

```bash
nix-instantiate --parse local-deriv/modernz.nix
nix build path:.#modernz-mpv -L --no-link --print-out-paths
nixos-rebuild dry-build --flake path:.
```

### Strata (`local-deriv/strata.nix`)

Strata v0.20.1 是键盘优先的 GTK4 文件管理器（上游 `lgse/strata`，MIT）。上游只发布预编译 tarball（AUR 走 `strata-bin`），这里从源码构建：

- 源码：固定 tag `v0.20.1`，`src` 用 `fetchFromGitHub`；`Cargo.lock` 的 373 个 crate 全部来自 crates.io，用 `rustPlatform.fetchCargoVendor` 一次锁定。
- flake 入口：`nix build path:.#strata`；消费者 `home/productivity/files.nix`。
- 输出：`bin/strata`（wrapGAppsHook4 包装：`PATH` 含上游 `install.sh` 的 REQUIRED_PACKAGES、`GST_PLUGIN_SYSTEM_PATH_1_0` 指向 GStreamer 插件、`GDK_PIXBUF_MODULE_FILE` 指向 pixbuf loader）、desktop entry、hicolor 图标、`share/licenses/strata/`，以及声明包管理器归属的 `share/strata/install-source.toml`（据此禁用应用内自更新）。
- 与上游依赖清单的两处偏差：`ffmpeg` → `ffmpeg-headless`（应用只调用命令行 ffmpeg/ffprobe）、不带 `gst-plugins-bad`（上游 REQUIRED_PACKAGES 不含它）。裁剪前后闭包 1168 MiB → 1060 MiB。
- `doCheck = false`：上游 `scripts/check.sh` 的 GUI 用例需要显示服务器（上游另用 Xvfb 跑 `test-headless.py`），Nix 构建沙箱里没有。

**NixOS 沙箱适配（本地补丁）**：预览与缩略图在 bubblewrap 里渲染，而上游 `src/sandbox.rs` 的 `runtime_command()` 写死 FHS 布局——`--ro-bind /usr /usr`、`--setenv PATH /usr/bin`、`/usr/bin/prlimit`，且不 bind `/nix/store`。未打补丁时复刻上游参数实测：

```text
prlimit: failed to execute /app/strata: No such file or directory
bwrap: execvp /app/strata: No such file or directory
# 追加 --ro-bind /nix/store /nix/store 后恢复正常输出：strata 0.20.1
```

原因是 helper 的 ELF 解释器与库都在 `/nix/store` 里，而不是缺依赖。`local-deriv/strata-nixos-sandbox.patch` 因此只改参数构造，不动命名空间/`clearenv`/Landlock/seccomp 边界：

| 改动 | 说明 |
| --- | --- |
| `--ro-bind-try /nix/store` | 让 helper 的解释器与库可见（只读） |
| 沙箱内 `PATH` / `prlimit` | 由编译期 `option_env!` 换成 store 路径，来源是 derivation 的 `STRATA_SANDBOX_PATH`、`STRATA_SANDBOX_PRLIMIT` |
| `GST_PLUGIN_SYSTEM_PATH_1_0` | 由 `STRATA_SANDBOX_GST_PLUGIN_PATH` 注入，媒体解码需要 |
| `--ro-bind /usr` → `--ro-bind-try /usr` | NixOS 上 `/usr` 可能只有 `env`，工具不再依赖它 |

补丁用 `option_env!` + `unwrap_or`，缺编译期变量时退回上游的 `/usr/bin` 行为，便于对照。沙箱内的 PATH 与包装脚本一致（`lib.makeBinPath runtimeTools`）。

`bwrap` 本身由 `trusted_command::resolve` 从固定系统目录（`/run/current-system/sw/bin` 等）查找、不读 `PATH`，所以 `host/base/services.nix` 把 `pkgs.bubblewrap` 放进 `environment.systemPackages`；这是补丁之外唯一必需的集成项。

已验证：用打完补丁的参数构造复刻调用真实 helper，图片缩略图输出 `256x144` PNG、视频缩略图输出 `128x96` PNG。GUI 内的实际预览、媒体播放（`preview-media`）与 GVfs 访问仍须 switch 后人工验证。

**曾试过但无效的补丁（已回退）**：标题栏侧栏开关的选中态会渲染成一个浅色圆盘、图标看不见。给 `src/style.css` 补 `.sidebar-toggle:checked` 规则没有任何效果——原因是 `~/.config/gtk-4.0/gtk.css` 指向运行时 Material-Gnome 主题的 `gtk.css`，GTK 按 **USER 优先级（800）**加载它，高于应用的 APPLICATION（600）；该主题的 `button:checked/:active { border-radius: 999px; background-color: var(--primary); color: var(--on_primary) }` 因此压过应用样式，而 Strata 的标题栏图标是**按 accent 预渲染的纹理**（`assets::primary_icon_color()`）、不吃 CSS `color`，M3 的 `primary` 又很浅，于是图标溶进填充色。实测（在宿主上跑部署版 + 在运行时主题 CSS 里注入探针）：`.sidebar-toggle`、`.sidebar-toggle:checked`、`button:checked`、`headerbar button` 加 `!important` 都改不动那块填充，只有万能选择器 `headerbar *` 的背景能盖住它。所以这条要么走主题侧（改 `local-deriv/material-gnome` 的 checked 填充，桌面全局生效），要么走上游（让该图标用能随状态翻转的颜色）；应用侧 CSS 无解。

验证（构建与集成）：

```bash
nix-instantiate --parse local-deriv/strata.nix
nix build path:.#strata -L --no-link --print-out-paths
nixos-rebuild dry-build --flake path:.#MechRevo-NixOS   # 容器内要显式指定主机名
```

## 更新已有包

升级前重新检查 changelog、许可证、构建系统、lockfile 和 release artifact。`nix-update` 可辅助修改，但完成后仍须人工审查 diff、重新构建、检查产物并运行 smoke test。

只有多次更新已经证明步骤稳定时才添加 `passthru.updateScript`，不为每个本地包预设更新框架。

## 故障排查

### 开发 shell 能编译，正常构建失败

`nix develop` 与 sandbox build 不完全等价。回到 `nix build path:.#<pname> -L`，按 unpack、patch、configure、build、check、install、fixup 的实际失败阶段处理。

### 程序构建成功但运行时找不到命令

如果程序通过 `PATH` 调用外部工具，仅放入 `buildInputs` 不够。使用 wrapper 或绝对 store path，并检查最终闭包。

### GUI 命令可运行但启动器不可见

检查 `$out/share/applications`、desktop entry 的 `Exec`、图标安装位置，以及 Home Manager 是否安装了正确输出。dry-build 不代表 launcher 已经刷新。

### 出现意外的大闭包

```bash
nix path-info -S path:.#<pname>
nix why-depends path:.#<pname> <依赖 store path>
```

先定位依赖路径，再调整输入或 wrapper，不要凭体积猜测。

## 相关链接

- [约束与惯例](../constraints.md) — overlay、override、direct import 与验证边界
- [部署与维护](../deployment.md) — dry-build、switch 和回滚
- [文件管理器与归档工具](../productivity/files.md) — Strata 的用法、已知限制与回退
- [nix.dev：打包现有软件](https://nix.dev/tutorials/packaging-existing-software.html)
- [Nixpkgs Standard Environment](https://nixos.org/manual/nixpkgs/stable/#chap-stdenv)
- [Nixpkgs package tests](https://github.com/NixOS/nixpkgs/blob/master/pkgs/README.md#package-tests)
