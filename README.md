# MechRevo-NixOS Config

NixOS 个人配置，基于 flakes + Home Manager。

## 系统概览

| 项目 | 内容 |
|------|------|
| 系统 | NixOS 26.05 (Yarara) |
| WM | Hyprland (Wayland) |
| Shell | fish (plugins) + bash (ble.sh) + starship + zellij |
| 桌面面板 | Noctalia Shell |
| 终端 | Ghostty |
| 文件管理器 | Yazi (HM module + 9 插件 + myargonaut 绿色主题 + 6 备选) |
| 输入法 | fcitx5 + rime-ice |
| 编辑器 | Neovim (kickstart + lazy.nvim, LSP/completion/telescope) |
| 代理 | mihomo (TUN 模式) |
| 云同步 | OneDrive (HM programs.onedrive) |

## 目录结构

```
├── flake.nix                  # 入口，inputs/outputs 定义
├── flake.lock
├── hardware-configuration.nix # 自动生成，不要手动改
│
├── host/                      # NixOS 系统级
│   ├── default.nix            # 入口
│   ├── core.nix               # 启动、内核、网络、时区、locale、用户
│   ├── desktop.nix            # Hyprland、fcitx5、字体、AMD 显卡
│   ├── services.nix           # PipeWire、蓝牙、CUPS、Mihomo
│   ├── packages.nix           # overlay、系统包、programs
│   └── litellm.nix            # LiteLLM 代理
│
├── home/                      # Home Manager 用户级
│   ├── default.nix            # 入口 + git 配置
│   ├── packages.nix           # 日常软件、开发工具
│   ├── shell.nix              # bash + starship + zellij + ghostty
│   ├── hyprland.nix           # Hyprland WM 配置
│   ├── noctalia.nix           # Noctalia shell 面板
│   ├── nvim.nix               # Neovim (kickstart 风格, lazy.nvim)
│   ├── yazi.nix               # Yazi (HM module + starship/yatline + myargonaut 主题)
│   ├── btop.nix               # btop 系统监控 (blackgolden 主题 + 透明背景)
│   ├── onedrive.nix           # OneDrive 同步
│   └── fonts-extra.nix        # 额外字体: PingFang, HarmonyOS Sans
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

## 注意事项

- 显卡/网卡驱动改动要谨慎
- 2K 屏 Hyprland scaling 已配 (1.5)，改 DPI/scale 时注意

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

| 文件 | 需要修改的内容 |
|------|---------------|
| `host/core.nix` | `networking.hostName`、`time.timeZone`、`i18n.defaultLocale`、`users.users.<name>` |
| `home/default.nix` | `home.username`、`home.homeDirectory` |
| `home/hyprland.nix` | `monitor` 显示器配置 |
| `flake.nix` | `nixosConfigurations.<hostname>`、`home-manager.users.<name>` |

### 3. 挂载 /persist 子卷并创建文件

`/persist` 是 btrfs 子卷（`@persist`），需在分区时创建并挂载。mihomo 和 LiteLLM 依赖其下的配置文件，首次部署需手动准备：

```bash
# 创建目录
sudo mkdir -p /persist/mihomo /persist/secrets

# mihomo 代理配置（必需，否则 mihomo 服务启动失败）
sudo cp <your-mihomo-config.yaml> /persist/mihomo/config.yaml

# LiteLLM 环境变量（可选，仅当使用 LiteLLM 代理时需要）
sudo cp <your-litellm.env> /persist/secrets/litellm.env
```

`/persist/secrets/litellm.env` 格式（`KEY=VALUE`，fish shell 启动时自动加载到用户环境）：
```
ANTHROPIC_AUTH_TOKEN=your-token
ANTHROPIC_BASE_URL=http://127.0.0.1:4000
OPENAI_API_KEY=your-litellm-master-key
OPENAI_BASE_URL=http://127.0.0.1:4000/v1
DEEPSEEK_API_KEY=your-deepseek-key
LITELLM_MASTER_KEY=your-litellm-master-key
```

> `ANTHROPIC_AUTH_TOKEN` 和 `ANTHROPIC_BASE_URL` 是客户端变量，供 Claude Code 等工具连接 LiteLLM 代理使用。`OPENAI_API_KEY` + `OPENAI_BASE_URL` 供 Codex 等 OpenAI 兼容工具使用。`DEEPSEEK_API_KEY` 和 `LITELLM_MASTER_KEY` 是 LiteLLM 服务端变量。

GitHub CLI 等工具也可能依赖 `/persist/secrets/` 下的其他 env 文件：
```bash
sudo cp <your-gh.env> /persist/secrets/gh.env
```

### 4. 用户文件和缓存

以下文件路径使用 `config.home.homeDirectory` 动态解析，但文件本身需要存在：

| 文件 | 用途 | 缺失时影响 |
|------|------|-----------|
| `~/Pictures/ProfiePictures/` | Noctalia 头像 | 头像不显示 |
| `~/Pictures/Wallpapers/` | Noctalia 壁纸 | 壁纸功能不可用 |
| `~/.cache/noctalia/HVE/` | Noctalia HVE 配置 | Hyprland 装饰配置缺失 |
| `~/.config/hypr/noctalia/` | Noctalia 颜色配置 | Hyprland 颜色回退到默认 |

首次启动 Noctalia 后，`~/.cache/noctalia/HVE/` 和 `~/.config/hypr/noctalia/` 会自动生成。

### 5. 应用配置

```bash
sudo nixos-rebuild switch --flake ~/myNixOSConfig#
```

### 6. 首次认证

- **OneDrive**: 终端运行 `onedrive` 完成 OAuth 认证
- **mihomo**: 确保 `/persist/mihomo/config.yaml` 中的订阅链接有效
