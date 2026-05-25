# NixOS Config — Claude Code Context

## 机器信息
- Hostname: `MechRevo-NixOS`
- Username: `lishangshui`
- 系统: NixOS 26.05 (Yarara) with flakes + Home Manager
- WM: Hyprland (Wayland)
- Shell: bash (通过 Home Manager 管理)
- 代理工具: mihomo (TUN 模式，配置 `/persist/mihomo/config.yaml`)
- GPU: AMD (amdgpu 驱动)

## 目录结构
主目录 `~/myNixOSConfig`，在此目录内 rebuild。rebuild 命令：
```bash
cd ~/myNixOSConfig && sudo nixos-rebuild switch --flake .
```
`/etc/nixos` 为旧备份，不作为源。

## 配置结构约定
- `flake.nix` — 入口，inputs/outputs 定义
- `configuration.nix` — 系统级配置（服务、内核、用户等）
- `home.nix` — Home Manager，用户级软件和 dotfiles
- `noctalia.nix` — Noctalia shell 自定义配置 (HM 模块)
- `litellm.nix` — LiteLLM 相关系统配置
- `hardware-configuration.nix` — 自动生成，不要手动大改

## 已启用服务
- **显示**: Hyprland (Wayland), Noctalia shell (Quickshell 面板)
- **输入法**: fcitx5 (rime-ice + moegirl + zhwiki 词库)
- **音频**: PipeWire (pulse/alsa/jack)
- **蓝牙**: bluetooth + blueman
- **打印**: CUPS
- **代理**: mihomo TUN 模式 (nftables 防火墙 + ip_forward)
- **电源**: thermald + power-profiles-daemon + upower
- **SSD**: fstrim

## 注意事项
- 修改后**不要自动 rebuild**，给出命令让我手动执行
- 优先用 Home Manager 管用户级配置，系统级才动 configuration.nix
- 涉及 overlay 或 unstable channel 的包，说明原因
- 不要提交 secrets（密码、API key 等）到 git
- 硬件相关（显卡、网卡驱动）改动要谨慎，先说明影响
- 2K 显示屏，Hyprland scaling 已配置，涉及 DPI/scale 改动时注意
