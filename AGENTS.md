# myNixOSConfig — Codex 工作约束

这是 `lishangshui` 的 NixOS flakes + Home Manager 配置仓库。

## 环境

- 主机：MechRevo-NixOS，AMD Ryzen 7 8845HS，Radeon 780M，2560x1600。
- 主 DE：Hyprland + niri，均经 UWSM 从 kmscon TTY 会话启动。
- GNOME：`specialisation/gnome/` 独立变体，不能依赖主 DE 配置。
- Shell：fish + bash/ble.sh；终端：Foot；输入法：fcitx5；代理：mihomo TUN。

## 配置边界

- 系统集成、硬件、网络、启动、字体和服务放 `host/`。
- 用户配置、桌面应用和工具放 `home/`；能由 Home Manager 管理的用户配置优先放 HM。
- 自定义且不在 nixpkgs 的包放 `local-deriv/`，直接 import；不要为单点包创建 overlay。
- `hardware-configuration.nix` 自动生成，除非用户明确要求不要手改。
- secrets 只放 `/persist/secrets/` 或 sops 加密文件，不进 git。
- 不修改网络/TUN、内核、AMD 背光、硬件、sudo 规则和 secrets，除非用户明确要求。

## 包分类硬规则

- 按主要用途单一归类：系统集成放 `host/`，共享环境放 `home/env/`，生产力放 `home/productivity/`，开发放 `home/dev/`，娱乐放 `home/leisure/`，DE 专属内容放对应的 `host/de/` 或 `specialisation/gnome/`。
- 支撑包跟随实际消费者；公共系统能力放 `host/`，用户应用放 `home/`，禁止重复声明。
- 新增包先检查已有声明和 nixpkgs；改动后同步导入关系与 Wiki 来源映射，并执行 parse 和 dry-build。
- 分类结构不是永久固定的；现有目录无法合理容纳时，允许新增、删除、合并或重命名目录/模块，但必须同步迁移导入、文档和来源映射。

## 当前结构

```text
host/
├── default.nix
├── base/                 # 两个桌面变体共享的系统层
└── de/                   # 主 DE 的系统集成：sessions.nix、greeter.nix

home/
├── base.nix              # 两个桌面变体共享的 HM 入口
├── de.nix                # 主 DE HM 入口
├── de/                   # Hyprland/niri、Foot、Stylix、Shell
├── env/                  # Shell、系统工具、OneDrive
├── dev/                  # 编辑器、AI、开发工具、容器
├── productivity/         # 办公、通讯、文件管理、图像工具、Yazi
└── leisure/              # 浏览器、影音、游戏

specialisation/gnome/     # 完全隔离的 GNOME 系统与 HM 入口
wiki/                     # 怎么用；_sources.yaml 是配置来源清单
memory/                   # 为什么这么配；本地知识库，不进 Git
.agents/skills/           # 项目通用技能单一真源
```

## 验证与应用

修改带自校验的配置时，先用包自带工具校验，再写入 Nix：

```bash
niri validate -c ~/.config/niri/config.kdl
hyprland --verify-config
```

通用检查：

```bash
nix-instantiate --parse <file>
nixos-rebuild dry-build --flake .
```

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
