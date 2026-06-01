# MechRevo-NixOS Config

NixOS 个人配置，基于 flakes + Home Manager。

## 系统概览

| 项目 | 内容 |
|------|------|
| 系统 | NixOS 26.05 (Yarara) |
| WM | Hyprland (Wayland) |
| Shell | bash + starship + zellij |
| 桌面面板 | Noctalia Shell |
| 终端 | Ghostty |
| 输入法 | fcitx5 + rime-ice |
| 代理 | mihomo (TUN 模式) |

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
│   ├── gh.nix                 # GitHub CLI
│   └── yazi.nix               # Yazi 文件管理器
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
