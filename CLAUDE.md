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
- 显示管理器: Noctalia Greeter (与桌面环境自动同步主题和壁纸)
- WM: Hyprland (Wayland), **Lua 配置** (`hyprland.lua`), scrolling layout
- Shell: fish (plugins: autopair/done/grc/colored-man-pages) + bash (ble.sh 语法高亮/自动补全)
- 终端: foot (系统级配置，host/desktop.nix)，默认 shell: fish
- 代理: mihomo TUN 模式 + nftables 防火墙，webui: zashboard (127.0.0.1:9090)

## 文件系统 (Btrfs subvolumes)
```
/          → subvol=@       (系统根)
/home      → subvol=@home   (用户目录)
/nix       → subvol=@nix    (nix store)
/persist   → subvol=@persist (持久化数据: mihomo.env, secrets)
/var/log   → subvol=@log    (日志)
/boot      → vfat (EFI 分区)
```

## 目录结构

```
myNixOSConfig/
├── flake.nix                  # 入口 — 依赖声明 + 模块引用，不含 inline 包定义
├── flake.lock                 # root 拥有，更新需 sudo
├── hardware-configuration.nix # 自动生成，不要手动大改
├── assets/
│   └── yamadaryou.png         # Noctalia Greeter/桌面 壁纸 + Hyprland 锁屏
│
├── overlays/                  # nixpkgs overlays，按文件分离
│   ├── default.nix            # 入口 — imports 所有 overlay 为 list
│   └── vim-plugins.nix        # vimPlugins 别名
│
├── local-deriv/                # 自定义包（不在 nixpkgs 中的全新包）

│   ├── netease-cloud-music-web-player.nix
│   ├── animeko.nix
│   ├── qoder-ide.nix           # Qoder CN — AI IDE (Electron)
│   ├── aionui.nix              # AionUi — AI agent 桌面协作平台
│   ├── anthropic-fonts.nix   # Anthropic 字体
│   └── anthropic-fonts.nix     # Anthropic Serif/Sans/Mono
│
├── host/                      # NixOS 系统级配置（基础设施，不放用户包）
│   ├── default.nix            # 入口 — 仅 imports
│   ├── boot.nix               # systemd-boot, EFI, /boot 安全设置, stateVersion
│   ├── hardware.nix           # AMD GPU, udev rules, nix-ld
│   ├── locale.nix             # 时区, locale, console 字体/键盘
│   ├── nix.nix                # nix 配置: flakes, substituters, allowUnfree
│   ├── users.nix              # 用户声明, groups, sudo rules
│   ├── network.nix            # NetworkManager, mihomo TUN, nftables, firewall, 网络诊断工具
│   ├── services.nix           # PipeWire, 蓝牙, CUPS, 电源管理, fstrim, gvfs
│   ├── desktop.nix            # 环境变量, Hyprland, fcitx5, 系统字体, touchpad, XDG portal, foot
│   ├── greeter.nix            # Noctalia Greeter 显示管理器
│   ├── litellm.nix            # LiteLLM 代理 (0.0.0.0:4000, DeepSeek API 后端)
│   └── gaming.nix             # Steam, 32-bit graphics, Flatpak, libvirtd
│
├── home/                      # Home Manager 用户级配置（按用途分子目录）
│   ├── default.nix            # 入口 — 仅 imports + username/stateVersion
│   ├── git.nix                # Git 用户配置
│   ├── theme.nix              # 指针光标, CJK字体(MS原生优先+fallback), qt5ct, 图标主题, dconf 默认
│   ├── env/                   # 桌面环境
│   │   ├── shell.nix          # starship, zellij, bash/ble.sh, fish + CLI工具 (eza/fzf/bat/...)
│   │   ├── hyprland.nix       # Hyprland Lua 配置 + Wayland 工具 + 截图
│   │   ├── terminal.nix       # (foot 在 host/desktop.nix)
│   │   ├── noctalia.nix       # Noctalia shell 面板
│   │   ├── systools.nix       # btop, yazi, fastfetch, 系统工具
│   │   └── onedrive.nix       # OneDrive 同步
│   ├── dev/                   # 开发工具
│   │   ├── nvim.nix           # Neovim
│   │   ├── nvim/init.lua      # Neovim 配置文件
│   │   ├── vscode.nix         # VS Code
│   │   ├── tools.nix          # direnv, gh, CLI 工具
│   │   ├── ai.nix             # claude-code, codex, codex-desktop, claude-desktop, qoder-cli, qoder-ide, officecli, pi, reasonix, opencode, cc-switch
│   │   └── containers.nix     # distrobox assemble manifest (arch + ubuntu)
│   ├── productivity/          # 办公与通讯
│   │   ├── office.nix         # LibreOffice, OnlyOffice, Obsidian + Markdown 编辑器
│   │   ├── comms.nix          # QQ, Telegram, WeChat(缩放), LocalSend
│   │   ├── files.nix          # Nemo 桌面配置 + 文件管理器 + 归档工具
│   │   └── compat.nix         # virt-manager, Flatseal (Flatpak 权限管理)
│   └── leisure/               # 影音、游戏与浏览器
│       ├── player.nix         # mpv, 网易云(gtk/web), OBS, go-musicfox, loupe, animeko
│       ├── browser.nix        # Firefox, Chrome
│       └── gaming.nix         # mangohud
│
├── docs/                      # 使用指南 + 约束
│   ├── nixos-constraints.md   # 详细约束与惯例（CLAUDE.md 精简版，冲突时以它为准）
│   ├── hyprland.md
│   ├── noctalia.md
│   ├── nvim.md
│   ├── shell.md
│   ├── litellm.md
│   ├── mihomo.md
│   ├── distrobox.md
│   └── yazi.md
│
├── CLAUDE.md
└── README.md
```

## 配置原则
- **按职责分模块**：每个文件只负责一个关注点
- **系统级** → `host/`，**用户级** → `home/`
- `hardware-configuration.nix` 由 nixos-generate-config 自动生成，不手动修改
- 包管理：基础 CLI/系统服务走系统包（`host/`），桌面应用走用户包（`home/`）
- Hyprland 配置走 Lua（`hyprland.lua`），不是 hyprlang `.conf` 文件

### Overlay / override / direct import 选择规则

**用 `nixpkgs.overlays` 仅当：**
- 向已有 attrset 添加名字，且其他模块通过 `pkgs.*` 引用（如 `pkgs.vimPlugins.some-alias`）
- 被修改的包有反向依赖也需要看到新版本

**用 `overrideAttrs` 内联（不要 overlay）当：**
- 修补一个只在一处使用的包
- 该包没有反向依赖需要变更

**用 `local-deriv/*.nix` + 直接 import 当：**
- 定义一个不在 nixpkgs 中的全新包
- 模式：`(import ../local-deriv/foo.nix { inherit pkgs; })`
- 如果 derivation 需要本地 `assets/` 路径，把 `src` 作为参数传入：
  ```nix
  # local-deriv/foo.nix
  { pkgs, src }: pkgs.stdenv.mkDerivation { inherit src; ... }
  # 调用方
  (import ../local-deriv/foo.nix { inherit pkgs; src = ../assets/foo.tar.gz; })
  ```

**禁止把新包定义放进 `nixpkgs.overlays`。**

### flake.nix
- `flake.nix` 只做入口和依赖声明
- Flake inputs: nixpkgs, home-manager, noctalia, noctalia-greeter, nix-flatpak, llm-agents (numtide/llm-agents.nix, AI 工具包来源), codex-desktop-linux (ilysenko, Codex Desktop for Linux)
- Overlays 放 `overlays/`，通过 `nixpkgs.overlays = import ./overlays` 导入
- 不允许 inline derivations、inline `mkDerivation`、inline `appimageTools`

### 去重规则
- 网络诊断工具 (`dnsutils iputils tcpdump mtr nmap iperf3 ethtool iptables`) **只在** `host/network.nix` 的 `environment.systemPackages` 中声明
  → 不要加到任何 `home/` 模块
- 字体包放 `local-deriv/fonts.nix`，由 `home/theme.nix` 导入
- 不要把一个包的 override 拆到两个模块（如 src 在 overlay、flags 在 home 模块 → 合并到一处）

### 链式 override
当一个包需要多个修改（新 src + 额外 flags + desktop entry），在一个 `overrideAttrs` 调用中完成。

如果通过 `xdg.desktopEntries` 定义了 `.desktop` 文件，`exec` 行**不**应重复 `postInstall` 中 `wrapProgram` 已经注入的 flags。

### systemd user services
`programs.onedrive` (HM) 只管理配置文件 — 它**不**生成 systemd user service。`home/env/onedrive.nix` 中手写的 `systemd.user.services.onedrive` 是有意为之且必须的。不要删除它。

### sudo rules
`host/users.nix` 中的 NOPASSWD 规则（`nix`, `nixos-rebuild`, `tee`, `chmod`, `chown`, `install`, `mv`, `cp`, `rm`）是**有意为之**的（单用户笔记本）。不要删除或收紧它们。

### 作用域与风格
`home.packages = with pkgs; [ ... ]` 内，裸名（不带 `pkgs.` 前缀）即使在嵌套 `let...in` 表达式中也能正确解析。两种写法都可以接受，不要仅为风格一致性做批量重命名。

## rebuild 命令
```bash
cd ~/myNixOSConfig && sudo nixos-rebuild switch --flake .
```

## 验证命令
```bash
# 语法检查（只查语法，不跑 evaluation）
nix-instantiate --parse <file>

# 完整 evaluation 检查（捕获类型错误、缺参数、坏 import）
cd ~/myNixOSConfig && sudo nixos-rebuild dry-build --flake .
```
语法通过不代表 evaluation 通过。结构性的修改（新增文件、移动包、改 import 路径）必须跑 `dry-build`。

## 已启用服务
- **启动**: systemd-boot (EFI)
- **显示管理器**: Noctalia Greeter (通过 greetd)
- **显示**: Hyprland (Wayland, Lua 配置, scrolling layout), Noctalia shell (Quickshell 面板)
- **输入法**: fcitx5 (rime-ice + moegirl + zhwiki 词库)
- **音频**: PipeWire (pulse/alsa/jack)
- **蓝牙**: bluetooth + blueman
- **打印**: CUPS
- **代理**: mihomo TUN 模式 (nftables 防火墙 + ip_forward + zashboard webui)，配置模板 Nix 管理，节点/规则从订阅自动更新
- **电源**: thermald + power-profiles-daemon + upower
- **SSD**: fstrim
- **深色模式**: Noctalia 调度 (dconf/qt5ct) + xdg-desktop-portal-gtk 暴露 Settings portal
- **云同步**: OneDrive (systemd user service, 首次需 `onedrive` 认证)
- **AI 代理**: LiteLLM (0.0.0.0:4000, 将 Claude/GPT API 路由到 DeepSeek 后端)
- **二进制兼容**: nix-ld (运行非 NixOS 编译的二进制)
- **文件管理**: gvfs
- **USB 自动挂载**: udiskie (systemd user service)
- **udev**: stlink, openocd
- **Steam**: programs.steam + 32-bit OpenGL/Vulkan (host/gaming.nix)
- **Flatpak**: services.flatpak + nix-flatpak 声明式管理
- **虚拟化**: libvirtd + QEMU/KVM + virt-manager
- **Android 容器**: Waydroid (LXC, binder, waydroid-nftables)
- **Nix 管理**: nh (CLI helper + systemd timer 每周 GC, 保留 10 代 + 7 天)

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
- **Cache mirrors**: cache.nixos.org, TUNA, USTC, SJTU
- **Features**: nix-command, flakes
- **allowUnfree**: true
- **stateVersion**: 25.11

## 注意事项

- **MS CJK 字体**: `/persist/Fonts/` 存放从 Windows 提取的字体文件（不进 git）。`home.activation.copyMsCjkFonts` 在 rebuild 时复制到 `~/.local/share/fonts/MS/`。`20-ms-office-cjk.conf` 配置原生优先的 fallback 链。**不要删除 `/persist/Fonts/` 下的字体文件。**
- **查包强制多路径**：Nix 没有模糊搜索，查 options/module 时至少尝试 2-3 种路径/方式（`nix eval` 换路径、搜 HM/NixOS 源码树、MyNixOS 在线文档），禁止一次查不到就手搓模块
- **查阅文档**：在修改配置或排查问题前，必须先查阅本地官方文档，如 `~/Documents/noctalia-docs-v5` 或 `docs/`，确认官方支持的配置方式。
### 分支隔离
- **main 分支必须保持可工作、可部署状态**。任何可能破坏系统的实验性改动（尤其是网络、显示、启动相关）必须在 feature 分支上进行
- 涉及 mihomo / TUN / nftables / DNS 等网络基础设施的改动，**一律开 feature 分支**。原因：网络组件出问题时可能阻断 nixos-rebuild（缓存下载走 TUN → 代理坏了 → SSL 失败 → 无法 rebuild 恢复），形成死锁
- feature 分支验证通过（rebuild 成功 + 服务正常运行）后再合并回 main
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
