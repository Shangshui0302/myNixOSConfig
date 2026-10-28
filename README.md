# myNixOSConfig

MechRevo-NixOS 的 NixOS flakes + Home Manager 配置。

## 当前系统

| 项目 | 配置 |
| --- | --- |
| 系统 | NixOS 26.05，nixos-unstable |
| 主桌面 | Hyprland（UWSM）+ niri（niri-session），greetd + tuigreet TTY |
| 变体 | GNOME specialisation，独立 GDM 会话 |
| Shell | fish、bash/ble.sh、Starship、zellij |
| 终端 | Foot，由 Home Manager 管理，半透明背景与合成器模糊 |
| 文件夹默认打开 | 主桌面 Strata；GNOME 变体 Nautilus |
| AI 工具 | Codex 与 Antigravity CLI、Antigravity 2.0 Agents 界面；AO 自主开发协作与 Arch DSH 桥接；Agent Reach 与 OpenCLI 平台访问工具；Token Monitor 由 Arch 安装并通过 Distrobox 导出 |
| 电子书与资料 | Z-Library 桌面客户端、Zotero 文献管理 |
| 面板 | Noctalia，可切换 Caelestia |
| 深浅模式 | Darkman 状态/portal + Matugen 运行时配色 |
| 输入法 | fcitx5 + Rime / WeTypeX |
| 网络 | mihomo TUN（本机 Sub-Store 生成与有效快照）+ Gist 模板分发 + nftables + Avahi mDNS 主机发现 |
| 配置方式 | NixOS + Home Manager，禁止手改生成配置 |

## 目录

```text
flake.nix                 # inputs、outputs、主机入口
host/
├── base/                 # 两个桌面变体共享的系统层与 Home Manager 集成
├── de/                   # 主 DE 的 sessions、portal、greeter
└── gnome/                # GNOME 系统层：default.nix（变体入口）、desktop.nix
home/
├── home.nix              # 主 DE HM 入口（base + theme/ + de/）
├── base.nix              # 共享 HM 入口
├── theme/                # 颜色/壁纸/主题域（base、gtk-matugen、gtk-static、runtime、wallpaper、stylix）
├── de/                   # Hyprland、niri、Foot、桌面 Shell
├── gnome.nix             # GNOME 变体 HM 入口（base + theme/gtk-static）
├── env/                  # Shell、系统工具、OneDrive
├── dev/                  # 编辑器、AI、开发工具、容器
├── productivity/         # 办公、通讯、文件管理（主 DE 保留 Strata）、图像工具、Yazi
└── leisure/              # 浏览器、影音、游戏
local-deriv/              # 不在 nixpkgs 的本地包
checks/                   # flake 检查入口：已有测试与仓库结构校验
scripts/                  # 仓库维护工具（来源映射检查）
tests/                    # Python 同步器测试与 Lua 事件 mock
wiki/                     # 操作手册与来源映射
memory/                   # 本地决策卡与硬件约束（不进 Git）
.agents/skills/           # 项目专用 skills
~/.agents/skills/         # 用户级共享 skills
```

本机 Sub-Store 操作说明：[`wiki/networking/sub-store.md`](wiki/networking/sub-store.md)。

Hyprland 滚动布局的单窗默认居中占显示器逻辑尺寸的 75%，多窗列宽默认约为三分之二；详见 [Hyprland 使用指南](wiki/desktop/hyprland.md#滚动布局-scrolling-layout)。

Hyprland 窗口焦点通过点击或快捷键切换，鼠标移过窗口不会自动抢焦点。

## 应用配置

```bash
cd ~/myNixOSConfig
nh os switch --hostname MechRevo-NixOS path:.
```

`path:.` 包含当前工作目录中尚未被 Git 跟踪的新文件。直接运行 `nh os switch` 使用默认 Git flake，会过滤这些文件；文件正式纳入 Git 后可继续使用无参数命令。上述命令会包含工作目录中的其他已有改动。

Codex 修改后只运行检查，不自动应用系统配置。结构性修改使用：

```bash
nix-instantiate --parse <file>
nixos-rebuild dry-build --flake path:.
```

统一检查由 `checks/default.nix` 维护，运行时依赖跟随 `flake.lock`：

- `mihomo-config-sync`：已有的 Python 同步器测试，不读取真实订阅或操作运行中的代理。
- `hyprland-policies`：`tests/` 目录中的 Lua 事件 mock，不启动或连接桌面会话。
- `repository-structure`：核对 Wiki 来源路径、文档和模块覆盖，以及重复的 YAML 条目。

```bash
nix flake check path:.
# 只运行来源映射检查：
nix build path:.#checks.x86_64-linux.repository-structure --no-link -L
# 使用锁定版本的格式化工具检查指定文件：
nix fmt -- --check flake.nix
```

这些检查不应用系统配置；`nix flake check --no-build` 只检查求值，不运行测试。Lua mock 也不替代桌面运行验证。本地 `memory/` 不进入 flake 检查，卡片核验方式见 [Flake 配置管理](wiki/architecture/flake.md#统一检查入口)。

## 常用入口

- [Wiki 首页](wiki/README.md)：按组件查找使用和排障说明。
- [GUI 权限授权](wiki/services.md#权限与安全)：polkit agent、Howdy 人脸认证与密码回退。
- [Wiki 来源清单](wiki/_sources.yaml)：Nix 模块与文档的映射。
- [Memory 索引](memory/INDEX.md)：查询非显而易见的配置决策。
- [项目约束](wiki/constraints.md)：包管理、变体、secrets 和验证规则。
- [Nix 手工打包](wiki/dev/nix-packaging.md)：`$nix-packaging`、本地派生和验证流程。
- [Agent Orchestrator](wiki/dev/agent-orchestrator.md)：Nix 安装、Arch DSH 接入与隔离试用。
- [Agent Reach 与 OpenCLI](wiki/dev/agent-reach.md)：平台访问、Chrome 扩展连接与字幕提取。
- [Token Monitor](wiki/dev/token-monitor.md)：Arch desktop 与 Distrobox 导出、登录自启、托盘弹窗与 Noctalia 连接。
- [Distrobox](wiki/dev/distrobox.md)：容器镜像、持久化 home、共用 Fish 配置与各环境独立的 PATH，以及 Home Manager 管理的容器启动器入口。

## 约束

- 系统级配置放 `host/`，用户级配置优先放 `home/`。
- `hardware-configuration.nix` 自动生成，不手动大改。
- secrets 放 `/persist/secrets/` 或 sops 加密文件，不进 git。
- Mihomo 的 bootstrap 沿用 `host/secrets/mihomo-gist.yaml` 中的加密数据；旧 Gist URL 不再部署。服务与更新集中在 `host/base/mihomo.nix`，运行快照保存在 systemd 管理的 `/var/lib/mihomo-config`，Sub-Store 数据库保存在 `/var/lib/sub-store`。
- 双机场规则在 Secret Gist 的 `mihomo-template.yaml` 编辑；独立 Sub-Store 实例读取模板和订阅生成成品，本机 NixOS 定时直接消费本机生成结果，其他客户端可订阅已发布的 `mihomo-dual.yaml`。NixOS 管服务与本机网络设置，rebuild 不覆盖 Sub-Store 订阅数据；各实例状态独立保存。
- 修改、生成、发布、三端更新和加密恢复见 [Mihomo 配置修改与分发](wiki/networking/mihomo-distribution.md)；本机服务的打开、恢复与停止见[本机 Sub-Store](wiki/networking/sub-store.md)。
- 任务分支使用 `feature/`、`fix/`、`docs/` 等用途前缀，禁止工具名称前缀。
- 投稿包在 `~/Projects/nixpkgs-maintain` 开发。Strata 1.0.0 暂用独立 `strata-nixpkgs` input 跟随 fork 的 `feature/strata` 分支，由 `flake.lock` 固定每次更新的版本；个人 Matugen 链保留在 `home/theme/`，官方频道可用后移除临时 input。
