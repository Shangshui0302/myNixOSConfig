---
name: nix-package
description: >
  为本仓库新增、升级、修复或审查 local-deriv 中的 Nix 包，并完成上游取证、
  构建入口、产物检查和集成验证。用户提到 Nix 打包、手工打包、更新本地派生、
  修复构建、AppImage/预编译二进制封装或 local-deriv 时必须使用。普通的软件安装、
  NixOS 模块配置和 nixpkgs 上游 PR 审查不触发本 skill。
---

# Nix Package

为 `~/myNixOSConfig` 维护可复现、可独立构建的本地包。先理解上游和真实产物，再写最小 derivation。

## 边界

- 遵守仓库 `AGENTS.md`：非小型工作先提交「问题 → 分析 → 解决」并等待确认。
- 先查 nixpkgs 与仓库已有实现；已有包或 helper 足够时复用，不新建本地包。
- 新包放 `local-deriv/<pname>.nix`，由消费者直接 `import`；单点修改优先 `overrideAttrs`，不建 overlay。
- GitHub 调查只用 `gh` CLI；其他网页可用浏览工具。以官方仓库、release、构建文档、CI 和许可证为准。
- 只修改包、必要消费者、flake 构建入口和关联文档。保留所有无关脏改动。
- 不使用非 Nix 包管理器，不自动 `nixos-rebuild switch`、commit、push 或创建 PR。

## 工作流

### 0. 运行时新鲜度门禁

每次执行都先读取 `flake.lock` 中的 nixpkgs revision，并定位 `inputs.nixpkgs` 的实际源码。针对本次要用的 builder/helper，同时核对：

1. 锁定源码中的函数参数、模块实现或同类成熟包；
2. 当前官方 [Nixpkgs Reference Manual](https://nixos.org/manual/nixpkgs/unstable/) 与 [nix.dev 打包教程](https://nix.dev/tutorials/packaging-existing-software.html)；
3. 本 skill 的 `references/` 是否仍与前两项一致。

锁定源码决定当前仓库实际可构建的接口，最新官方文档用于发现流程演进。二者不一致时，先向用户报告差异与迁移影响；不能把最新接口直接套到旧锁定输入，也不能因旧输入可构建而忽略已弃用流程。若确认是稳定的流程变化，在同一次受审查的改动中更新 skill、引用资料和 Wiki，并重新验证。skill 不得后台更新或自行改写。

### 1. 定义目标与取证

判断是新增、升级、修复还是审查，并记录预期程序、版本、平台和最小可观察行为。

1. 用 `rg` 搜索仓库中的同名包、命令、desktop entry 和消费者。
2. 通过 `builtins.getFlake`/`inputs.nixpkgs` 查询当前 flake 锁定的 nixpkgs 是否已有包或更合适的 builder/helper；registry/channel 搜索只能作线索，不能代替锁定版本结论。
3. 检查上游 README、构建文件、CI、release artifact、tag/commit、LICENSE、主程序名和安装布局。
4. 源码构建可行时优先源码；只有源码不可用或维护成本明显过高时才封装二进制/AppImage。

不要仅凭 `Cargo.toml`、`pyproject.toml` 等单个标记决定 builder；以真实构建命令和同类成熟 nixpkgs 包为准。

可用当前锁定输入做精确存在性检查：

```bash
nix eval --impure --expr 'let f = builtins.getFlake (toString ./.); p = f.inputs.nixpkgs.legacyPackages.x86_64-linux; in builtins.hasAttr "<attr>" p'
```

### 2. 选择实现路径

识别包类型后，读取 [references/builders.md](references/builders.md) 中对应章节。选择最窄的 nixpkgs builder 或 hook，优先默认 phases；只在必要时增加 `pre/post*`。

若完整覆盖 `buildPhase`、`installPhase` 等 phase，必须调用对应的 `runHook preX` 和 `runHook postX`。普通 `stdenv.mkDerivation` 应正确区分：

- 构建机上执行的工具和 setup hooks → `nativeBuildInputs`
- 最终程序链接或运行所需库 → `buildInputs`
- 测试时执行的工具 → `nativeCheckInputs`
- 运行时调用的外部程序 → 写入 store path 或用 wrapper 提供 `PATH`

避免 `propagatedBuildInputs`，除非下游使用者确实必须继承该依赖。

### 3. 编写最小包

- 沿用本仓库 `{ pkgs }:` 入口和直接 import 方式。
- 使用 `pname`、`version`、固定 `rev`/release URL 与 SRI `hash = "sha256-..."`。
- URL、tag 和文件名中的版本尽量引用 `${version}`，避免升级漏改。
- 哈希未知时优先在 packaging shell 中用 `nurl`；不能覆盖时用 `pkgs.lib.fakeHash` 构建并复制 mismatch 给出的真实值。
- Rust、Node 等第二层依赖哈希单独迭代；禁止在 sandbox build 中在线执行 `cargo fetch`、`npm install`、`pip install`。
- `meta` 至少核对 `description`、`homepage`、`license`、`mainProgram`、`platforms`；原生二进制 release 使用 `sourceProvenance = with pkgs.lib.sourceTypes; [ binaryNativeCode ];`，并复核随包组件许可证。
- 桌面程序同时处理并验证 wrapper、`.desktop`、图标和 `Exec`，不能把命令可运行等同于桌面集成完成。

在 `flake.nix` 的 `packages.${system}` 显式暴露包，保持 `nix build path:.#<pname>` 为统一独立构建入口。只有用户要求安装时才接入对应 NixOS/Home Manager 消费者；“打包进仓库”不自动等于安装。不要为注册包再增加一层 package-set 抽象。

### 4. 失败定位

按实际失败 phase 排查：unpack → patch → configure → build → check → install → fixup。先读完整日志：

```bash
nix build path:.#<pname> -L
nix log path:.#<pname>
```

需要交互诊断时可用 `nix develop path:.#<pname>` 逐 phase 调试，但最终结论必须回到 sandbox build；开发 shell 成功不等于包构建成功。不要用“缺什么都塞进 `buildInputs`”掩盖根因。

### 5. 验证与交付

读取并逐项执行 [references/checklist.md](references/checklist.md)。最低要求是：

```bash
nix-instantiate --parse local-deriv/<pname>.nix
nix flake check path:. --no-build
nix build path:.#<pname> -L --no-link --print-out-paths
nixos-rebuild dry-build --flake path:.
git diff --check
```

新文件未进入 Git 时使用 `path:.#...`，不要为了让 flake 看见文件而擅自暂存。根据包类型检查 store 输出并执行一个安全、非破坏性的 smoke test；GUI 包须明确哪些行为只能在用户 switch 后人工验证。

交付时分别报告：

1. derivation 是否构建成功；
2. 未部署的产物/smoke test 是否通过；
3. NixOS dry-build 是否通过；
4. 尚未执行的 `switch` 与运行时验证。

若要提交，转入 `project-commit` skill；打包完成本身不授权提交。

## 更新现有包

升级前重新检查 changelog、许可证、构建系统、lockfile 和 release artifact。更新版本与所有相关哈希后，审查实际 diff，再完整重建和 smoke test。`nix-update` 只是可选加速器；复杂表达式或一文件多包必须人工修改。只有已经证明存在稳定、重复更新流程时才增加 `passthru.updateScript`。
