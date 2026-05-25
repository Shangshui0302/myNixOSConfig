# MechRevo-NixOS Config

我的 NixOS 个人配置，基于 flakes + Home Manager。

源文件在 `~/myNixOSConfig/`，直接在目录内 rebuild：

```bash
cd ~/myNixOSConfig
sudo nixos-rebuild switch --flake .
```

## 系统概览

| 项目 | 内容 |
|------|------|
| 系统 | NixOS 26.05 (Yarara) |
| WM | Hyprland (Wayland) |
| Shell | bash |
| 桌面面板 | Noctalia Shell |
| 输入法 | fcitx5 + rime-ice |
| 代理 | mihomo (TUN 模式) |

## 目录结构

```
flake.nix               # 入口，定义 inputs/outputs
flake.lock              # 锁定依赖版本
configuration.nix       # 系统级配置（服务、内核、驱动等）
hardware-configuration.nix  # 硬件配置（自动生成，勿手动大改）
home.nix                # Home Manager — 用户级软件和配置
noctalia.nix            # Noctalia shell 自定义配置
litellm.nix             # LiteLLM 代理服务配置
```

## 常用命令

```bash
# 完整重建（系统 + Home Manager）
sudo nixos-rebuild switch --flake .

# 仅更新 flake inputs
sudo nixos-rebuild switch --flake . --update-input nixpkgs

# 手动更新 flake lock
nix flake lock --update-input nixpkgs
```

## 包管理原则

- **系统级** → `configuration.nix`（驱动、服务、系统工具）
- **用户级** → `home.nix`（编辑器、浏览器、日常软件）
- 改用户级配置不需要 sudo，`nixos-rebuild switch` 会自动处理

## 注意事项

- 不要在配置里硬编码 secrets（密码、API key 等）
- 涉及显卡/网卡驱动的改动要谨慎
- 2K 屏 Hyprland scaling 已配置，改 DPI/scale 时注意
