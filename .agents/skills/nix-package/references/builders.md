# Builder 路由

只读取与当前包类型对应的章节。builder 名称是起点，最终以当前 flake 锁定的 nixpkgs API、上游构建命令和成熟同类包为准。

## 源码包

| 上游形态 | 首选入口 | 关键检查 |
| --- | --- | --- |
| Autotools / Make | `stdenv.mkDerivation` | 先让默认 configure/build/install phases 工作 |
| CMake | `cmake` 放 `nativeBuildInputs` | 不手写与 hook 重复的 configure/build phase |
| Meson | `meson`、`ninja` 放 `nativeBuildInputs` | 检查 feature flags 与测试 |
| Rust | `rustPlatform.buildRustPackage` | `cargoHash` 或 `cargoLock`，含 git dependency 时核对 `outputHashes` |
| Go | `buildGoModule` | `vendorHash`，确认 `subPackages` 与版本注入 |
| Python 应用 | `python3Packages.buildPythonApplication` | `pyproject`、build-system、dependencies、import/pytest check |
| Node/npm | `buildNpmPackage` | lockfile、`npmDepsHash`、离线构建和最终 wrapper |

普通源码包优先设置构建 flags 或 `pre/post*`，不要整体重写默认 phase。只有上游没有标准安装过程时才自定义 phase，并保留 `runHook`。

官方参考：

- [Nixpkgs Standard Environment](https://nixos.org/manual/nixpkgs/stable/#chap-stdenv)
- [Rust](https://nixos.org/manual/nixpkgs/stable/#rust)
- [Python](https://nixos.org/manual/nixpkgs/stable/#buildpythonpackage-function)
- [JavaScript](https://nixos.org/manual/nixpkgs/stable/#javascript-tool-specific)

## 预编译 ELF

使用 `fetchurl` 固定发布产物；`dontUnpack` 只在输入确实是单文件时启用。通常从 `autoPatchelfHook` 开始，将动态库放 `buildInputs`。先用 `file`、`readelf -h` 核对格式和架构，用 `readelf -l`/`patchelf --print-interpreter` 核对解释器，再用 `readelf -d`、`patchelf --print-needed` 和实际启动错误确认动态库。

程序在运行时通过命令名调用 `ffmpeg`、`yt-dlp` 等工具时，用 `makeWrapper` 或绝对 store path；仅把工具放进 `buildInputs` 不保证运行时 `PATH`。检查程序没有硬编码 `/usr/bin/...`，并用一个安全 fixture 实际触发该外部命令；这与检查 ELF 链接库是两项不同验证。

原生二进制 release 使用 `sourceProvenance = with pkgs.lib.sourceTypes; [ binaryNativeCode ];`，同时核对 bundle 中第三方组件的许可证。

依次升级修复手段：正常 ELF patch → 有证据的手工 patch → 最小 FHS wrapper。不要默认使用 FHS，也不要用 `autoPatchelfIgnoreMissingDeps` 跳过未知问题。

参考：[Packaging binaries](https://wiki.nixos.org/wiki/Packaging/Binaries)

## AppImage

仅在传统源码打包不可行或维护代价明显更高时使用 `appimageTools`。先确认 Type 1/2，再选择 `wrapType1`/`wrapType2`；如需解出 desktop/icon，使用 `extractType*` 并显式安装资源。

检查：

- 最终 wrapper 的真实可执行名；
- AppImage 内 ELF 的 `NEEDED` 与随包库文件名；
- `.desktop` 的 `Exec`、`Icon` 和安装路径；
- Wayland、缩放或媒体运行库参数是否属于可复现的 wrapper 行为。

需要 `postExtract` 时按照当前手册选择支持它的接口，不要假设 `wrapType2` 会执行该 hook。

参考：[AppImage tools](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-appimageTools)

## Electron / ASAR

若上游发布可复用的 ASAR 或资源包，可用 nixpkgs 的 Electron 运行时加 wrapper；否则优先 `buildNpmPackage` 或上游对应的 Electron builder。必须安装并修正 desktop entry 与图标，同时确认 sandbox、Wayland 和 keyring flags 是否真正必要。

不要复制上游 `/usr/bin/...` 绝对路径。wrapper 中的 flags 与 Home Manager desktop entry 不得重复。

## 字体、主题和纯数据

用 `stdenvNoCC.mkDerivation` 或等价的无编译 derivation，安装到标准输出布局：字体在 `$out/share/fonts`，主题在 `$out/share/themes`。字体用 `fc-scan` 检查，主题检查预期文件和权限。

若构建期需要生成颜色或转换图像，仅把执行工具放 `nativeBuildInputs`；不要把它们误留在运行时闭包。

## Hyprland 插件

优先 `hyprlandPlugins.mkHyprlandPlugin`，确保源码 commit 与当前 nixpkgs 中的 Hyprland ABI 匹配。安装预期 `.so`，再由 Home Manager 配置加载。构建成功不能证明 compositor 已成功加载；switch 后还需检查 Hyprland 日志和插件列表。
