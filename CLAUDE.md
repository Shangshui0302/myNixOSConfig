# NixOS Config — Claude Code Context

## 机器信息
- Hostname: `MechRevo-NixOS`
- Username: `lishangshui`
- 系统: NixOS 26.05 (Yarara) with flakes + Home Manager
- WM: Hyprland (Wayland)
- Shell: fish (通过 Home Manager 管理)
- 代理工具: mihomo (TUN 模式，配置 `/persist/mihomo/config.yaml`)
- 终端: foot (系统级配置)
- GPU: AMD (amdgpu 驱动)

## 目录结构

```
myNixOSConfig/
├── flake.nix                  # 入口，inputs/outputs 定义
├── flake.lock
├── hardware-configuration.nix # 自动生成，不要手动大改
│
├── host/                      # NixOS 系统级配置
│   ├── default.nix            # 入口 — 导入所有子模块
│   ├── core.nix               # 启动、内核、网络、时区、locale、用户
│   ├── desktop.nix            # Hyprland、fcitx5、字体、AMD 显卡、环境变量
│   ├── services.nix           # PipeWire、蓝牙、CUPS、Mihomo、电源管理
│   ├── packages.nix           # overlay、系统包、programs 配置
│   └── litellm.nix            # LiteLLM 代理服务
│
├── home/                      # Home Manager 用户级配置
│   ├── default.nix            # 入口 — 导入子模块 + git 配置
│   ├── packages.nix           # 用户包（日常软件、开发工具等）
│   ├── shell.nix              # Fish、starship、zellij、ghostty
│   ├── hyprland.nix           # Hyprland WM 完整配置
│   ├── noctalia.nix           # Noctalia shell 面板完整配置
│   ├── yazi.nix               # Yazi 文件管理器主题
│   └── onedrive.nix           # OneDrive 同步 (HM programs.onedrive + systemd service)
│
├── CLAUDE.md
└── README.md
```

## 配置原则
- **按职责分模块**：每个文件只负责一个关注点（core/desktop/services/packages）
- **系统级** → `host/`，**用户级** → `home/`
- `hardware-configuration.nix` 由 nixos-generate-config 自动生成，不手动修改
- 包管理：基础 CLI 工具走系统包（`host/packages.nix`），桌面应用走用户包（`home/packages.nix`）

## rebuild 命令
```bash
cd ~/myNixOSConfig && sudo nixos-rebuild switch --flake .
```

## 已启用服务
- **显示**: Hyprland (Wayland), Noctalia shell (Quickshell 面板)
- **输入法**: fcitx5 (rime-ice + moegirl + zhwiki 词库)
- **音频**: PipeWire (pulse/alsa/jack)
- **蓝牙**: bluetooth + blueman
- **打印**: CUPS
- **代理**: mihomo TUN 模式 (nftables 防火墙 + ip_forward)
- **电源**: thermald + power-profiles-daemon + upower
- **SSD**: fstrim
- **云同步**: OneDrive (HM programs.onedrive, systemd user service `onedrive --monitor`，首次需手动 `onedrive` 认证)

## 注意事项
- 修改后**不要自动 rebuild**，给出命令让我手动执行
- 修改 Hyprland 配置后必须运行 `hyprland --verify-config` 诊断
- 优先用 Home Manager 管用户级配置，系统级才动 host/
- 涉及 overlay 或 unstable channel 的包，说明原因
- secrets 放 `/persist/secrets/`（如 `litellm.env`, `gh.env`），不进 git
- sudo 已配 NOPASSWD: nix, nixos-rebuild, tee, chmod, chown, install, mv, cp, rm
- 硬件相关（显卡、网卡驱动）改动要谨慎，先说明影响
- 2K 显示屏，Hyprland scaling 已配置，涉及 DPI/scale 改动时注意
- **所有改动必须通过 nixos-rebuild 应用，禁止用非 nix 方式（npm install、直接下载等）修改系统配置**
