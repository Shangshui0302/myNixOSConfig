{ config, lib, pkgs, ... }:

{
  # GNOME specialisation — 完整 GNOME 桌面（GDM Wayland 登录）。
  # 默认 boot 保持 kmscon + Hyprland/niri；开机在 systemd-boot 选 "NixOS (gnome)" 进 GNOME。
  # GDM 自动列出已装 wayland sessions（Hyprland / Hyprland (UWSM) / Niri / GNOME），可跨 DE 切换。
  specialisation.gnome.configuration = {
    services.desktopManager.gnome.enable = true;
    services.displayManager.gdm.enable = true;

    # GDM 接管 tty1。禁用 kmscon 避免边角问题（本机 kmscon 走 libseat=false raw-VT 特殊配置）。
    # base（greeter.nix）硬定义 enable=true，需 mkForce 覆盖。
    services.kmscon.enable = lib.mkForce false;

    # minimal-but-complete：只留 GNOME Shell + core services，不装 core apps。
    # 游戏 / 开发者工具默认已关（services.gnome.games / core-developer-tools 默认 false）。
    services.gnome.core-apps.enable = false;
    environment.gnome.excludePackages = with pkgs; [
      gnome-tour        # 在 core-shell optionalPackages（core-apps 之外）
      gnome-user-docs
    ];

    # fcitx5：GNOME Wayland 走 text-input-v3，官方建议不设 GTK_IM_MODULE
    # （GTK 应用用原生输入协议；Qt 走 QT_IM_MODULE，XWayland 走 XMODIFIERS）。
    # base（desktop.nix）的 GTK_IM_MODULE=fcitx 在此移除。
    environment.variables = {
      GTK_IM_MODULE = lib.mkForce null;
      QT_IM_MODULE = lib.mkForce "fcitx";
      XMODIFIERS = lib.mkForce "@im=fcitx";
    };
  };
}
