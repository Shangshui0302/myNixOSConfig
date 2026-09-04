# 打包检查清单

## 调查

- [ ] 已记录 `flake.lock` 中的 nixpkgs revision，并定位锁定输入的实际源码。
- [ ] 已核对本次 builder/helper 的锁定接口与当前官方 Nixpkgs/nix.dev 文档。
- [ ] 若两者或本 skill 的引用资料不一致，已报告差异、迁移影响并同步修正规范；未静默套用漂移接口。
- [ ] 仓库和 nixpkgs 中没有可直接复用的包或 helper。
- [ ] nixpkgs 结论来自当前 flake 锁定的 `inputs.nixpkgs`，不是漂移的 registry/channel。
- [ ] 已核对上游仓库、release/tag/commit、构建文档和 CI。
- [ ] 已核对 LICENSE、主程序名、平台、发布产物和安装布局。
- [ ] 已选择源码、预编译 ELF、AppImage、Electron、数据包或插件路线，并说明原因。

## Derivation

- [ ] 文件位于 `local-deriv/<pname>.nix`，由实际消费者直接 import。
- [ ] `pname`、`version`、源码引用和 SRI hash 固定且一致。
- [ ] 使用最窄的 builder/hook，没有复制默认 phases。
- [ ] 自定义 phase 保留 `runHook preX/postX`。
- [ ] 构建工具、链接/运行库、测试工具和运行时命令已正确分类。
- [ ] `meta` 来自上游证据；原生二进制包使用 `sourceTypes.binaryNativeCode` 并核对 bundled 组件许可证。
- [ ] GUI 包处理 desktop entry、icon、Exec 和 wrapper。
- [ ] `flake.nix` 暴露 `packages.${system}.<pname>`。
- [ ] 只有用户要求安装时才接入对应 NixOS/Home Manager 消费者。

## 构建与检查

```bash
nix-instantiate --parse local-deriv/<pname>.nix
nix flake check path:. --no-build
nix build path:.#<pname> -L --no-link --print-out-paths
git diff --check
```

- [ ] 阅读完整失败日志，没有用宽泛依赖或禁用测试掩盖错误。
- [ ] 检查 `$out/bin`、`$out/lib`、desktop、icon、字体或插件布局中与类型相关的内容。
- [ ] 对主程序执行一个安全的 `--version`、`--help` 或轻量真实调用。
- [ ] 预编译 ELF 已核对文件格式、架构、解释器和 `NEEDED`；运行时外部命令已排除 `/usr/bin` 硬编码并由 fixture 实际触发。
- [ ] GUI/守护进程不能安全启动时，记录未验证项，不伪称运行验证通过。
- [ ] 用 `nix path-info -S` 检查闭包；异常依赖用 `nix why-depends` 定位。

## 仓库集成

```bash
nixos-rebuild dry-build --flake path:.
```

- [ ] 消费者归类正确且没有重复声明。
- [ ] 对应 Wiki 与 `wiki/_sources.yaml` 已同步。
- [ ] 非显而易见的长期权衡才写 memory 卡；普通打包步骤只写 Wiki。
- [ ] 报告已构建、已 smoke、已 dry-build、未 switch 四种状态。
- [ ] 未自动 commit、push 或 `nixos-rebuild switch`。
