# MechRevo-NixOS Config

NixOS 个人配置，基于 flakes + Home Manager。

## 系统概览

| 项目         | 内容                                                     |
| ------------ | -------------------------------------------------------- |
| 系统         | NixOS 26.05 (Yarara)                                     |
| WM           | Hyprland (Wayland)                                       |
| Shell        | fish (plugins) + bash (ble.sh) + starship + zellij       |
| 桌面面板     | Noctalia Shell                                           |
| 终端         | Foot                                                    |
| 文件管理器   | Yazi (HM module + 9 插件 + myargonaut 绿色主题 + 6 备选) |
| 输入法       | fcitx5 + rime-ice                                        |
| 编辑器       | Neovim (kickstart + lazy.nvim, LSP/completion/telescope) |
| 代理         | mihomo (TUN 模式)                                        |
| 云同步       | OneDrive (HM programs.onedrive)                          |
| 游戏         | Steam + mangohud                                         |
| Windows 兼容 | virt-manager (KVM)                                       |
| 生物识别     | Howdy (IR 红外人脸解锁: sudo, greetd, noctalia)          |

## 目录结构

```
├── flake.nix                  # 入口，inputs/outputs 定义
├── flake.lock
├── hardware-configuration.nix # 自动生成，不要手动改
│
├── host/                      # 系统基础设施 (13 文件)
│   ├── default.nix            # 入口汇总
│   ├── boot.nix               # 启动与内核
│   ├── hardware.nix           # GPU、udev、nix-ld
│   ├── locale.nix             # 时区、locale、键盘
│   ├── nix.nix                # Nix 配置
│   ├── users.nix              # 用户与 sudo
│   ├── network.nix            # 网络、mihomo、防火墙
│   ├── services.nix           # PipeWire、蓝牙、CUPS、电源
│   ├── desktop.nix            # 桌面环境基础设施
│   ├── greeter.nix            # 显示管理器配置（纯 TTY 登录，无 DM）
│   ├── gaming.nix             # Steam、Flatpak、libvirtd
│   ├── containers.nix         # distrobox 容器
│   └── sops.nix               # secrets 解密
│
├── overlays/                  # nixpkgs overlays
│
├── local-deriv/               # 自定义包（qoder-ide、netease、animeko、rtk 等）
│
├── home/                      # 用户配置 (4 子目录)
│   ├── default.nix            # 入口汇总
│   ├── git.nix                # Git 配置
│   ├── theme.nix              # 主题、字体、深色模式、图标
│   ├── env/                   # 桌面环境
│   ├── dev/                   # 开发工具 (含 AI)
│   ├── productivity/          # 办公、通讯、Windows 兼容
│   └── leisure/               # 影音、游戏、浏览器
│
├── wiki/                      # 操作手册（怎么用 + 故障排查）
│   ├── README.md              # wiki 导航首页（分类 MOC）
│   ├── _sources.yaml          # 来源映射清单（单真源，驱动 doc-sync hook）
│   ├── overview.md            # 项目概述
│   ├── architecture/          # 系统架构: index/flake/host
│   ├── desktop/               # 桌面环境: hyprland/fcitx5/noctalia/shell/darkmode/keyring
│   ├── productivity/          # 生产力: office
│   ├── dev/                   # 开发与工具: nvim/vscode/yazi/distrobox/bottles
│   ├── leisure/               # 娱乐: gaming/media
│   ├── networking/            # 网络与代理: mihomo
│   ├── security/              # 安全与隐私: index/sops/pam
│   ├── customization/         # 定制与扩展: overlays
│   ├── services.md            # 系统服务聚合
│   ├── deployment.md          # 部署与维护（含新机首次部署）
│   ├── troubleshooting.md     # 故障排除聚合
│   └── constraints.md         # 约束与惯例
│
├── memory/                    # 决策记忆（为什么 + 硬件特性，AI 参考）
│   ├── INDEX.md               # 卡片索引
│   ├── _template.md           # 卡片模板
│   └── cards/                 # 原子化决策卡
│
├── CLAUDE.md
└── README.md
```

## rebuild

```bash
cd ~/myNixOSConfig && sudo nixos-rebuild switch --flake .
```

## 配置原则

- **系统级** → `host/`（驱动、服务、系统工具）
- **用户级** → `home/`（编辑器、浏览器、日常软件）
- 改用户级配置不需要 sudo，rebuild 自动处理
- 所有改动必须通过 nixos-rebuild 应用，禁止非 nix 方式修改
- secrets 走 `/persist/secrets/`，不进 git

## 新机器首次部署

### 0. 前置条件

确保已从 U 盘或网络获取本仓库：

```bash
git clone <repo-url> ~/myNixOSConfig
cd ~/myNixOSConfig
```

### 1. 生成硬件配置

```bash
nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix ~/myNixOSConfig/
```

### 2. 修改机器特定配置

| 文件                      | 需要修改的内容                                                     |
| ------------------------- | ------------------------------------------------------------------ |
| `host/network.nix`        | `networking.hostName`                                                  |
| `host/locale.nix`         | `time.timeZone`、`i18n.defaultLocale`                                |
| `host/users.nix`          | `users.users.<name>`、NOPASSWD 规则                                  |
| `home/default.nix`        | `home.username`、`home.homeDirectory`                                |
| `home/env/hyprland.nix`   | `hl.monitor` 显示器配置                                              |
| `flake.nix`               | `nixosConfigurations.<hostname>`、`home-manager.users.<name>`       |

### 3. 挂载 /persist 子卷并创建文件

`/persist` 是 btrfs 子卷（`@persist`），需在分区时创建并挂载。mihomo 依赖其下的配置，首次部署需手动准备：

```bash
# 创建目录
sudo mkdir -p /persist/mihomo

# mihomo 代理配置（必需，否则 mihomo 服务启动失败）
sudo cp <your-mihomo-config.yaml> /persist/mihomo/config.yaml
```

Secrets 通过 sops-nix + age 加密管理（`host/secrets/secrets.yaml`），解密私钥为系统 SSH host key（`/etc/ssh/ssh_host_ed25519_key`），随系统迁移无需单独管理。首次部署需生成 SSH host key（OpenSSH 默认自动生成），并确保 `.sops.yaml` 接收者与该 key 的 age 公钥匹配。

GitHub CLI 等工具也可能依赖 `/persist/secrets/` 下的其他 env 文件：

```bash
sudo cp <your-gh.env> /persist/secrets/gh.env
```

### 4. 用户文件和缓存

以下文件路径使用 `config.home.homeDirectory` 动态解析，但文件本身需要存在：

| 文件                           | 用途              | 缺失时影响              |
| ------------------------------ | ----------------- | ----------------------- |
| `~/Pictures/ProfiePictures/` | Noctalia 头像     | 头像不显示              |
| `~/Pictures/Wallpapers/`     | Noctalia 壁纸     | 壁纸功能不可用          |
| `~/.cache/noctalia/HVE/`     | Noctalia HVE 配置 | Hyprland 装饰配置缺失   |
| `~/.config/hypr/noctalia/`   | Noctalia 颜色配置 | Hyprland 颜色回退到默认 |

首次启动 Noctalia 后，`~/.cache/noctalia/HVE/` 和 `~/.config/hypr/noctalia/` 会自动生成。

### 5. 应用配置

```bash
sudo nixos-rebuild switch --flake ~/myNixOSConfig#
```

### 6. 首次认证

- **OneDrive**: 终端运行 `onedrive` 完成 OAuth 认证
- **mihomo**: 确保 `/persist/mihomo/config.yaml` 中的订阅链接有效
