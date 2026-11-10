# myNixOSConfig 工作约束

本仓库是 lishangshui 的 NixOS flakes + Home Manager 配置。主机 MechRevo-NixOS 使用 Ryzen 7 8845HS、Radeon 780M、2560×1600；主桌面为 greetd/tuigreet 启动的 Hyprland（UWSM）和 niri（原生 session）。NextKDE 使用 `host/nextkde/`、`home/nextkde.nix`，是 Plasma Wayland + SDDM + KOS 独立变体，不继承主桌面配置。

主桌面以 Darkman 为唯一深浅状态源，Matugen 渲染颜色；NextKDE 以 `kdeglobals` 为源，由 systemd 触发 `kos-colors` 分发，不写 KDE 主题。两条链的缓存和 Fcitx5 主题目录独立。Shell 为 fish + bash/ble.sh，终端 Foot，输入法 fcitx5，代理 mihomo TUN，主机发现 Avahi mDNS。

## 配置与包分类

- 系统集成、硬件、网络、启动、字体、服务放 `host/`；用户应用和配置放 `home/`，优先使用 Home Manager。按主要用途单一归类：共享环境 `home/env/`、生产力 `home/productivity/`、开发 `home/dev/`、娱乐 `home/leisure/`；桌面专属内容放对应 `host/de/`、`host/nextkde/`、`home/de/` 或 `home/nextkde.nix`。支撑包跟随消费者，公共系统能力放 `host/`，禁止重复声明。
- 长期本地包放 `local-deriv/` 直接 import，不为单点包创建 overlay。投稿包在 `~/Projects/nixpkgs-maintain` 的任务空间维护唯一包定义；本仓库只通过临时 input 消费验证过的固定提交和目标包，官方频道可用后移除 input。个人主题与配置留在 `home/`。
- 新增包先检查现有声明及 nixpkgs，同步导入关系和 Wiki 来源映射，执行 parse 和 dry-build。每个手工包在 `flake.nix` 暴露 `packages.${system}.<pname>`，以 `nix build path:.#<pname>` 独立构建。目录可按需调整，但须同步迁移导入、文档和来源映射。
- 自动生成的 `hardware-configuration.nix` 除非明确要求不得手改；secrets 只放 `/persist/secrets/` 或 sops 加密文件，不进 Git。网络/TUN、内核、AMD 背光、硬件、sudo 规则及 secrets 须经用户明确要求才能修改。
- 本地包新增、升级、修复和审查使用 `$nix-packaging`；上游 nixpkgs 维护及 PR 使用 `$nixpkgs-maintainer`；NixOS、Home Manager、服务、部署及恢复使用 `$nixos-ecosystem`。共享 skills 在 `~/.agents/skills/`，项目专用 skills 在 `.agents/skills/`。以锁定 revision 源码为接口依据，有新接口、更新或兼容性疑点时核对官方文档，可复用同 revision 有效证据。

共享系统层在 `host/base/`，共享 HM 入口为 `home/base.nix`，主桌面 HM 入口为 `home/home.nix`；`home/theme/` 管理主题，`checks/`、`scripts/`、`tests/` 提供检查，`wiki/_sources.yaml` 记录配置来源，`memory/` 是不入 Git 的本地知识库。

## 验证、应用与维护

配置只通过 Nix 修改，不直接编辑活动 dotfile。可先校验临时候选配置再写入 Nix，或先修改 Nix 再生成候选配置；niri 用 `niri validate -c <候选配置文件>`，Hyprland 使用该版本支持的候选配置校验方式。活动会话可用 `hyprctl configerrors` 检查；只有用户明确授权运行时应用后才执行 `hyprctl reload` 并检查。

通用检查为 `nix-instantiate --parse <file>` 和 `nixos-rebuild dry-build --flake .`。手工包进入 `nix develop .#packaging`，按 `$nix-packaging` 验证，并使用 `nix flake check path:. --no-build`、`nix build path:.#<pname> -L --no-link --print-out-paths` 和 `nixos-rebuild dry-build --flake path:.`。新文件未进入 Git 时使用 `path:.`，不得为使 flake 看见文件而擅自暂存。分别报告 derivation 构建、未部署 smoke test、系统 dry-build 和 switch 后运行验证；前三者不代表已应用。系统由用户手动运行 `sudo nixos-rebuild switch --flake .`，不自动 rebuild；root 操作由用户执行。

涉及启动、显示或网络的实验使用独立任务 worktree，保留已有脏改动。修改 Nix、移动模块或删除功能后同步 README、wiki 来源清单和必要 memory 卡；提交前使用 `project-commit`，会话收尾使用 `session-wrapup`。`.vscode/`、`.codex/` 和本地排障记录不进 Git。

优先删除已确认不再被 import、引用或运行时需要的内容，优先使用 NixOS/HM 原生模块；不为单一实现增加抽象，复杂配置按职责拆分。不删除用户明确保留的编辑器、容器或常用应用，只清理死代码、重复实现和过期文档。
