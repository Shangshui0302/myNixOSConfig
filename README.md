# myNixOSConfig

MechRevo-NixOS 的 NixOS flakes + Home Manager 配置。

## 当前系统

| 项目 | 配置 |
| --- | --- |
| 系统 | NixOS 26.05，nixos-unstable |
| 主桌面 | Hyprland（UWSM）+ niri（niri-session），greetd + tuigreet TTY |
| 变体 | GNOME specialisation，独立 GDM 会话 |
| Shell | fish、bash/ble.sh、Starship、zellij |
| 终端 | Foot，由 Home Manager 管理 |
| 面板 | Noctalia，可切换 Caelestia |
| 深浅模式 | Darkman 状态/portal + Matugen 运行时配色 |
| 输入法 | fcitx5 + Rime |
| 网络 | mihomo TUN + nftables |
| 配置方式 | NixOS + Home Manager，禁止手改生成配置 |

## 目录

```text
flake.nix                 # inputs、outputs、主机入口
host/
├── base/                 # 两个桌面变体共享的系统层
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
├── productivity/         # 办公、通讯、文件管理、图像工具、Yazi
└── leisure/              # 浏览器、影音、游戏
local-deriv/              # 不在 nixpkgs 的本地包
wiki/                     # 操作手册与来源映射
memory/                   # 本地决策卡与硬件约束（不进 Git）
.agents/skills/           # 项目通用 skills
```

## 应用配置

```bash
cd ~/myNixOSConfig
sudo nixos-rebuild switch --flake .
```

Codex 修改后只运行检查，不自动应用系统配置。结构性修改使用：

```bash
nix-instantiate --parse <file>
nixos-rebuild dry-build --flake .
```

## 常用入口

- [Wiki 首页](wiki/README.md)：按组件查找使用和排障说明。
- [Wiki 来源清单](wiki/_sources.yaml)：Nix 模块与文档的映射。
- [Memory 索引](memory/INDEX.md)：查询非显而易见的配置决策。
- [项目约束](wiki/constraints.md)：包管理、变体、secrets 和验证规则。
- [Nix 手工打包](wiki/dev/nix-packaging.md)：`$nix-package`、本地派生和验证流程。

## 约束

- 系统级配置放 `host/`，用户级配置优先放 `home/`。
- `hardware-configuration.nix` 自动生成，不手动大改。
- secrets 放 `/persist/secrets/` 或 sops 加密文件，不进 git。
- 网络、内核、硬件和启动相关改动使用 `codex/` feature 分支。
