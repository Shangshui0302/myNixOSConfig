# NixOS Config — Claude Code Context

## 硬件信息
- 机型: MechRevo (机械革命) 笔记本
- CPU: AMD Ryzen 7 8845HS (8核16线程)
- GPU: AMD Radeon 780M (HawkPoint1, amdgpu 驱动)
- 内存: 32GB
- 硬盘: NVMe SSD, Btrfs 文件系统
- 屏幕: 2K (2560x1600), Hyprland scale 1.5

## 系统信息
- Hostname: `MechRevo-NixOS`
- Username: `lishangshui`
- 系统: NixOS 26.05 (Yarara) with flakes + Home Manager
- 启动: systemd-boot + EFI (可触控 EFI 变量)
- 显示管理器: SDDM (sddm-astronaut 主题，自定义 yamadaryou 壁纸，猫ppuccin 配色)
- WM: Hyprland (Wayland), **Lua 配置** (`hyprland.lua`), scrolling layout
- Shell: fish (plugins: autopair/done/grc/colored-man-pages) + bash (ble.sh 语法高亮/自动补全)
- 终端: foot (系统级) + ghostty (用户级), 默认启动 fish
- 代理: mihomo TUN 模式 + nftables 防火墙，webui: metacubexd (127.0.0.1:9090, secret: 030222)

## 文件系统 (Btrfs subvolumes)
```
/          → subvol=@       (系统根)
/home      → subvol=@home   (用户目录)
/nix       → subvol=@nix    (nix store)
/persist   → subvol=@persist (持久化数据: mihomo config, secrets)
/var/log   → subvol=@log    (日志)
/boot      → vfat (EFI 分区)
```

## 目录结构

```
myNixOSConfig/
├── flake.nix                  # 入口，inputs: nixpkgs, home-manager, noctalia, noctalia-qs
├── flake.lock                 # root 拥有，更新需 sudo
├── hardware-configuration.nix # 自动生成，不要手动大改
├── assets/
│   └── yamadaryou.png         # SDDM 壁纸 + Hyprland 锁屏
│
├── host/                      # NixOS 系统级配置（基础设施，不放用户包）
│   ├── default.nix            # 入口 — 仅 imports
│   ├── boot.nix               # systemd-boot, EFI, /boot 安全设置, stateVersion
│   ├── hardware.nix           # AMD GPU, udev rules, nix-ld, steam (基础硬件设施)
│   ├── locale.nix             # 时区, locale, console 字体/键盘
│   ├── nix.nix                # nix 配置: flakes, substituters, allowUnfree
│   ├── users.nix              # 用户声明, groups, sudo rules
│   ├── network.nix            # NetworkManager, mihomo TUN, nftables, firewall, 网络诊断工具
│   ├── services.nix           # PipeWire, 蓝牙, CUPS, 电源管理, fstrim, gvfs
│   ├── desktop.nix            # 环境变量, Hyprland, fcitx5, 系统字体, touchpad, XDG portal, foot
│   ├── sddm.nix               # SDDM 显示管理器 (astronaut 主题定制)
│   └── litellm.nix            # LiteLLM 代理 (0.0.0.0:4000, DeepSeek API 后端)
│
├── home/                      # Home Manager 用户级配置（按用途分子目录）
│   ├── default.nix            # 入口 — 仅 imports + username/stateVersion
│   ├── git.nix                # Git 用户配置
│   ├── theme.nix              # 指针光标, CJK字体回退, 额外字体, qt5ct, darkman, 图标主题
│   ├── env/                   # 桌面环境
│   │   ├── shell.nix          # starship, zellij, bash/ble.sh, fish + CLI工具 (eza/fzf/bat/...)
│   │   ├── hyprland.nix       # Hyprland Lua 配置 + Wayland 工具 + 截图
│   │   ├── terminal.nix       # (foot 在 host/desktop.nix)
│   │   ├── noctalia.nix       # Noctalia shell 面板
│   │   ├── systools.nix       # btop, yazi, fastfetch, 系统/网络工具
│   │   └── onedrive.nix       # OneDrive 同步
│   ├── dev/                   # 开发工具
│   │   ├── nvim.nix           # Neovim
│   │   ├── nvim/init.lua      # Neovim 配置文件
│   │   ├── vscode.nix         # VS Code
│   │   ├── tools.nix          # direnv, gh, CLI 工具
│   │   └── ai.nix             # claude-code, codex, gemini-cli
│   ├── productivity/          # 办公与通讯
│   │   ├── office.nix         # WPS(缩放), LibreOffice, Obsidian
│   │   ├── comms.nix          # QQ, Telegram, WeChat(缩放), LocalSend
│   │   └── files.nix          # Nemo 桌面配置 + 文件管理器 + 归档工具
│   └── media/                 # 影音与浏览器
│       ├── player.nix         # mpv, 网易云(gtk/web/yesplaymusic), OBS, go-musicfox, loupe
│       └── browser.nix        # Firefox, Chrome
│
├── docs/                      # 使用指南
│   ├── hyprland.md
│   ├── noctalia.md
│   ├── nvim.md
│   ├── shell.md
│   ├── litellm.md
│   ├── mihomo.md
│   └── yazi.md
│
├── CLAUDE.md
└── README.md
```

## 配置原则
- **按职责分模块**：每个文件只负责一个关注点
- **系统级** → `host/`，**用户级** → `home/`
- `hardware-configuration.nix` 由 nixos-generate-config 自动生成，不手动修改
- 包管理：基础 CLI/系统服务走系统包（`host/packages.nix`），桌面应用走用户包（`home/packages.nix`）
- Hyprland 配置走 Lua（`hyprland.lua`），不是 hyprlang `.conf` 文件

## rebuild 命令
```bash
cd ~/myNixOSConfig && sudo nixos-rebuild switch --flake .
```

## 已启用服务
- **启动**: systemd-boot (EFI)
- **显示管理器**: SDDM (sddm-astronaut 自定义主题)
- **显示**: Hyprland (Wayland, Lua 配置, scrolling layout), Noctalia shell (Quickshell 面板)
- **输入法**: fcitx5 (rime-ice + moegirl + zhwiki 词库)
- **音频**: PipeWire (pulse/alsa/jack)
- **蓝牙**: bluetooth + blueman
- **打印**: CUPS
- **代理**: mihomo TUN 模式 (nftables 防火墙 + ip_forward + metacubexd webui)
- **电源**: thermald + power-profiles-daemon + upower
- **SSD**: fstrim
- **深色模式**: darkman (经纬度 30.57/104.07 成都, 自动切换 dconf/qt5ct)
- **XDG Portal**: Hyprland + darkman settings backend
- **云同步**: OneDrive (systemd user service, 首次需 `onedrive` 认证)
- **AI 代理**: LiteLLM (0.0.0.0:4000, 将 Claude/GPT API 路由到 DeepSeek 后端)
- **二进制兼容**: nix-ld (运行非 NixOS 编译的二进制)
- **文件管理**: gvfs
- **Emoji**: wofi-emoji (Super+. 符号/emoji 选择器)
- **udev**: stlink, openocd

## LiteLLM 模型映射 (端口 4000)
所有模型通过 DeepSeek API 后端提供，环境变量 `DEEPSEEK_API_KEY` 在 `/persist/secrets/litellm.env`:

| 模型名 | 后端模型 | 用途 |
|--------|---------|------|
| claude-opus-4-7 | deepseek-v4-pro (anthropic) | Claude Code |
| claude-sonnet-4-6 | deepseek-v4-flash (anthropic) | 日常使用 |
| claude-haiku-4-5 | deepseek-v4-flash (anthropic) | 轻量任务 |
| gpt-4o / gpt-4.1 | deepseek-v4-pro (openai) | Codex CLI 等 |
| gpt-4o-mini | deepseek-v4-flash (openai) | 备选 |

Fallback: opus→sonnet→haiku, gpt-4o/4.1→gpt-4o-mini

## Nix 配置
- **Channel**: nixos-unstable
- **Cache mirrors**: cache.nixos.org + TUNA (mirrors.tuna.tsinghua.edu.cn)
- **Features**: nix-command, flakes
- **allowUnfree**: true
- **stateVersion**: 25.11

## 注意事项
- **查包强制多路径**：Nix 没有模糊搜索，查 options/module 时至少尝试 2-3 种路径/方式（`nix eval` 换路径、搜 HM/NixOS 源码树、MyNixOS 在线文档），禁止一次查不到就手搓模块
- **每次改动后**：更新 README.md 和 CLAUDE.md → commit → rebuild → push main（private repo，不需要 PR）
- 修改后**不要自动 rebuild**，给出命令让我手动执行
- 修改 Hyprland 配置后必须运行 `hyprland --verify-config` 诊断
- 优先用 Home Manager 管用户级配置，系统级才动 host/
- 涉及 overlay 或 unstable channel 的包，说明原因
- secrets 放 `/persist/secrets/`（如 `litellm.env`），不进 git；fish shell 启动时自动 source
- API 密钥通过 `/persist/secrets/litellm.env` 注入，不在 nix 配置中硬编码
- sudo 已配 NOPASSWD: nix, nixos-rebuild, tee, chmod, chown, install, mv, cp, rm
- 硬件相关（显卡、网卡驱动）改动要谨慎，先说明影响
- 2K 显示屏 2560x1600，Hyprland scale 1.5，涉及 DPI/scale 改动时注意
- 鼠标: epic-mouse-v1，sensitivity -0.5
- **所有改动必须通过 nixos-rebuild 应用，禁止用非 nix 方式修改系统配置**
- flake.lock 被 root 拥有，更新 flake inputs 需 sudo
