{ config, lib, pkgs, inputs, ... }:
{
  # caelestia-dots/shell — Hyprland 桌面 shell，与 Noctalia/DMS 互斥（都抢 org.freedesktop.Notifications DBus）。
  # 由 shell-switcher 运行时切换：默认 Noctalia，set caelestia 切到 caelestia。
  # 注：caelestia 强制 quickshell-git（git.outfoxxed.me 外部源），依赖面大（fish/ddcutil/brightnessctl/lm_sensors 等）。
  imports = [
    inputs.caelestia.homeManagerModules.default
  ];

  programs.caelestia = {
    enable = true;
    settings = { }; # 留空用默认；声明式配置后续按需加
  };

  # caelestia service 不自动拉起（wantedBy 置空），由 shell-switcher 手动启停，
  # 避免与 Noctalia/DMS 同时激活（DBus 冲突）。
  systemd.user.services.caelestia.Install.WantedBy = lib.mkForce [ ];
}
