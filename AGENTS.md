# myNixOSConfig — Codex 工作约束

这是 `lishangshui` 的 NixOS flakes + Home Manager 配置仓库。

## 环境

- 主机：MechRevo-NixOS，AMD Ryzen 7 8845HS，Radeon 780M，2560x1600。
- 主 DE：Hyprland（UWSM）+ niri（原生 `niri-session`），均由 greetd/tuigreet TTY 会话启动。
- GNOME：`host/gnome/`（系统层）+ `home/gnome.nix`（HM 入口）独立变体，不能依赖主 DE 配置。
- Shell：fish + bash/ble.sh；终端：Foot；输入法：fcitx5；代理：mihomo TUN。
- 主桌面深浅模式：Darkman 是唯一状态源，Matugen 负责运行时取色与模板渲染。

## 配置边界

- 系统集成、硬件、网络、启动、字体和服务放 `host/`。
- 用户配置、桌面应用和工具放 `home/`；能由 Home Manager 管理的用户配置优先放 HM。
- 自定义且不在 nixpkgs 的包放 `local-deriv/`，直接 import；不要为单点包创建 overlay。
- 新增、升级、修复或审查 `local-deriv/` 包时必须使用用户级 `$nix-packaging` skill；面向上游 Nixpkgs 的包维护与 PR 使用 `$nixpkgs-maintainer`；NixOS、Home Manager、服务、部署和恢复任务使用 `$nixos-ecosystem`。共享 skills 安装在 `~/.agents/skills/`，`.agents/skills/` 只保留本项目专用 skills。每次先核对锁定 nixpkgs 接口与当前官方文档，再完成上游取证、方案确认、修改和验证。
- `hardware-configuration.nix` 自动生成，除非用户明确要求不要手改。
- secrets 只放 `/persist/secrets/` 或 sops 加密文件，不进 git。
- 不修改网络/TUN、内核、AMD 背光、硬件、sudo 规则和 secrets，除非用户明确要求。

## Agent 协作

- 对跨多个文件或目录、需要独立调查/验证、代码审查、实验监控等非小型任务，默认主动使用 subagent；用户不必显式要求。
- 优先用 multiagent 并行处理互不依赖的只读探索、方案比较、测试和审查；存在数据依赖、写同一文件或可能冲突时改为串行。
- 主 agent 负责理解目标、拆分任务、限定权限、合并结果和最终验证；subagent 只处理边界明确的子任务，并返回证据、修改文件和检查结果。
- 派发任务时说明目标、输入、文件范围、禁止事项和交付格式；禁止多个 agent 同时修改同一文件。
- 子任务完成后必须审阅输出和 diff，运行最小相关检查，不能盲目采纳 subagent 的结论或修改。
- 单行、单文件且明确的小改动直接处理，避免为此启动 agent。
- 所有 agent 都必须遵守本文件的 Nix、secret、Git、破坏性操作和“不自动 rebuild”规则；需要 root 或外部权限时只返回命令，由用户执行。

## 包分类硬规则

- 按主要用途单一归类：系统集成放 `host/`，共享环境放 `home/env/`，生产力放 `home/productivity/`，开发放 `home/dev/`，娱乐放 `home/leisure/`，DE 专属内容放对应的 `host/de/`、`host/gnome/` 或 `home/de/`、`home/gnome.nix`。
- 支撑包跟随实际消费者；公共系统能力放 `host/`，用户应用放 `home/`，禁止重复声明。
- 新增包先检查已有声明和 nixpkgs；改动后同步导入关系与 Wiki 来源映射，并执行 parse 和 dry-build。
- 每个手工包必须在 `flake.nix` 暴露 `packages.${system}.<pname>`，以 `nix build path:.#<pname>` 作为统一独立构建入口。
- 分类结构不是永久固定的；现有目录无法合理容纳时，允许新增、删除、合并或重命名目录/模块，但必须同步迁移导入、文档和来源映射。

## 当前结构

```text
host/
├── default.nix
├── base/                 # 两个桌面变体共享的系统层
├── de/                   # 主 DE 的系统集成：sessions.nix、greeter.nix
└── gnome/                # GNOME 系统层：default.nix（变体入口）、desktop.nix

home/
├── home.nix              # 主 DE HM 入口（base + theme/ + de/）
├── base.nix              # 两个桌面变体共享的 HM 入口
├── theme/                # 颜色/壁纸/主题域：base、gtk-matugen、gtk-static、runtime、wallpaper、stylix
├── de/                   # Hyprland/niri、Foot、桌面 Shell
├── gnome.nix             # GNOME 变体 HM 入口（base + theme/gtk-static）
├── env/                  # Shell、系统工具、OneDrive
├── dev/                  # 编辑器、AI、开发工具、容器
├── productivity/         # 办公、通讯、文件管理、图像工具、Yazi
└── leisure/              # 浏览器、影音、游戏
wiki/                     # 怎么用；_sources.yaml 是配置来源清单
memory/                   # 为什么这么配；本地知识库，不进 Git
.agents/skills/           # 项目专用 skills（project-commit/session-wrapup/wiki-maintainer）
~/.agents/skills/         # 用户级共享 skills（nix-packaging/nixpkgs-maintainer/nixos-ecosystem）
```

## 验证与应用

修改带自校验的配置时，先用包自带工具校验，再写入 Nix：

```bash
niri validate -c ~/.config/niri/config.kdl
hyprland --verify-config
```

对于运行中的 Hyprland，会话重载后再检查活动配置（应无输出）：

```bash
hyprctl reload
hyprctl configerrors
```

通用检查：

```bash
nix-instantiate --parse <file>
nixos-rebuild dry-build --flake .
```

手工打包进入锁定到本 flake 的开发环境，并按 `$nix-packaging` 流程验证：

```bash
nix develop .#packaging
nix flake check path:. --no-build
nix build path:.#<pname> -L --no-link --print-out-paths
nixos-rebuild dry-build --flake path:.
```

必须分别报告 derivation 构建、未部署 smoke test、系统 dry-build 和 switch 后运行验证；前三项成功不代表配置已经应用。新文件未进入 Git 时使用 `path:.`，不得为让 flake 看见文件而擅自暂存。

系统应用由用户手动执行，Codex 不自动 rebuild：

```bash
sudo nixos-rebuild switch --flake .
```

当前环境如需 root 权限，用户自行执行命令；不要用非 Nix 包管理器改系统。

## Git 与文档

- 破坏启动、显示或网络的改动在 `codex/` feature 分支完成；不要在 `main` 做实验。
- 保留用户已有脏改动，不使用 destructive reset/checkout 覆盖它们。
- 修改 Nix、移动模块或删除功能后，同步 README、wiki 来源清单和必要的 memory 卡。
- 提交前使用 `project-commit` skill；会话收尾使用 `session-wrapup` skill。
- `.vscode/`、`.codex/` 和本地排障记录不进 git。

## 维护偏好

- 删除优先：先确认是否仍被 import、引用或运行时需要。
- 优先使用 NixOS/Home Manager 原生模块，避免手写生成器和重复包声明。
- 不为单一实现增加抽象层；复杂配置保持按职责拆分。
- 不删除用户明确保留的编辑器、容器或常用应用，只清理死代码、重复实现和过期文档。
