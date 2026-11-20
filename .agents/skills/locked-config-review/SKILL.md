---
name: locked-config-review
description: 在 myNixOSConfig 按当前 flake.lock 审阅和优化 NixOS/Home Manager 配置。用于判断本地补丁能否删除、上游模块能否替代、主题脚本是否破坏用户状态，以及区分「现在修、等升级、保留、待实机验收」。先只读取证，按授权分批修改；不负责升级、提交或部署。
---

# 按锁定版本审阅与优化

先回答：**在哪个锁定版本、什么输入下，会产生什么后果？** 如果只能回答「有更新的写法」，不要改。以下路径均相对仓库根目录。系统和 HM 接口结合 `$nixos-ecosystem` 核对，本地包和构建产物结合 `$nix-packaging` 核对。

## 1. 固定比较基线

- 记录 `git rev-parse HEAD`、`git status --short`、Nix 版本和相关输入在 `flake.lock` 中的 revision。基线是**当前工作树**，包含用户改动和已完成的批次，不是干净的 HEAD。只读审阅不回写；获准「自行优化」也不包含提交、更新锁、切换系统或操作真实会话。
- 从消费者倒查：主机 → `home/home.nix`，`specialisation.nextkde.configuration` → `home/nextkde.nix`。NextKDE 不是第二个 flake 主机。读锁定源码中的 option、默认值及启用条件；区分 flake 暴露的包与系统 `.override` 后实际使用的包。上游 `main` 或新版本手册不能证明当前可替换。
- 日常从 Git flake `.` 求值。若需要未跟踪文件，先审阅已跟踪改动，再用 `scripts/flake-candidate.py` 逐个点名允许的普通文件。保留一份不改的基线 A，仅从该候选复制出 B 做实验；不要直接复制整个仓库，也不要为验证暂存文件。`cleanSourceWith` 发生在 flake 取源之后，不是保密边界。

## 2. 给每个发现一个决定

| 决定 | 所需证据与下一步 |
| --- | --- |
| 现在修 | 可复现故障，或锁定上游已接管且 A/B 证明本地实现冗余。写明触发条件、后果和能区分新旧的检查。 |
| 等升级 | 只有未锁定的包集、提交或 PR 提供所需能力。写明哪个输入变化后重查；不顺手升级。 |
| 保留 | 替代品缺少正在使用的能力，或改写没有维护收益。记录决定性差异，例如 Lua 相同但缺中文资源。 |
| 待实机验收 | 版号或 `PATH` 不同只是线索。写出要在什么会话做什么、观察什么算通过；不预设故障，不先改权限。 |

只读请求到此交付。已授权实施时，每批只解决一个可独立说明、验证和撤回的问题。

## 3. 用对照决定怎么改

| 场景 | 最小有效对照 |
| --- | --- |
| 删除兼容补丁 | 在同一装配中只撤补丁，对比 HM generation 或目标 `drvPath`。预期包路径改变时，实际构建无补丁包，检查 Shell 内置依赖、用户命令、补全是否落在同一包；不能只看模块能 eval。 |
| 改用原生接口 | 比较配置文件、hook 路径、可执行位、shebang、参数和服务所有者。迁移 Darkman hook 不应额外启动 HM 服务；具名模板替换要检查遗漏变量。若只是为静态配置引入生成工具，先看构建计划再决定是否保留原写法。 |
| 写偏好或激活脚本 | 在临时 HOME 用合成文件先复现旧行为。分别测首次创建、已有自定义值、非法输入和重复运行。只改本组件拥有的键：Fcitx5 竖排是首次默认，不是策略；Strata 改根键不能破坏合法 TOML。HM 的 `run` 须包住重定向和子进程；用 `DRY_RUN=1` 验证无写入、无会话调用，并跑非预演对照。 |
| 修缓存与并发 | 用同键重跑模拟缺失或空产物，用可控的锁等待复现旧状态覆盖新状态。断言能自愈、失败仍保留上次发布结果、内容相同不额外写入或唤醒监听。不要靠随机循环碰运气。 |

测试使用临时 HOME/XDG 目录、合成数据和模拟会话命令，不读真实偏好、订阅或秘密。硬件、内核、网络/TUN、sudo、权限变更和真实会话测试均需另行授权。

## 4. 分层验证，再回写

按变更选能证明结论的最小检查。下面是 Bash 示例：从仓库根运行；`extras` 必须填齐本次配置依赖且已审阅的未跟踪文件。若采用 A/B，在 B 上运行同样检查。

```bash
(
  set -eu
  extras=()  # 在数组中逐项填写仓库相对路径；没有才留空
  candidate=$(python3 scripts/flake-candidate.py "${extras[@]}")
  cd -- "$candidate"
  nix flake check --no-update-lock-file --no-build path:.
  # 主题变更示例；其他批次替换为相应 check 或包
  nix build --no-update-lock-file --no-link -L path:.#checks.x86_64-linux.theme-apply
  host='path:.#nixosConfigurations.MechRevo-NixOS.config'
  nix build --no-update-lock-file --dry-run --no-link \
    "$host.system.build.toplevel" "$host.specialisation.nextkde.configuration.system.build.toplevel"
)
```

- 对改过的 Nix 文件先做 `nix-instantiate --parse`。分别记录 **parse、eval、实际构建/测试、缓存复用、store 产物冒烟、系统 dry-build、部署后实机结果**。`--no-build` 不运行检查，dry-build 只给计划；要求离线时先看计划，缺依赖不要触发下载。
- 回写前确认涉及的工作树文件仍与 A 一致；如已变化，停止覆盖，重新取基线。只应用 A→B 的本批差异，逐文件对比 B，运行 `git diff --check`。按 `wiki-maintainer` 同步受影响的 README/Wiki、来源映射和确已过时的决策卡；版本、默认值、安装步骤都从同一把锁核对。
- 交付写清：**改了什么及证据｜哪些测试实际运行、哪些复用｜哪些保留或等升级｜哪些仍需实机验收**。不要把「已回写工作树」写成「活动桌面已修复」。
