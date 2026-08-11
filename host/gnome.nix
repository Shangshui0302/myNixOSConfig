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

    # 全量 GNOME：core apps（nautilus/epiphany/text-editor 等）+ 游戏 + 开发者工具全上。
    # core-apps 默认即 true（显式声明表明意图）；games / core-developer-tools 默认 false，需打开。
    # 注意：全量含 Epiphany → 拉入 webkitgtk 大包，首次构建/下载较慢。
    services.gnome.core-apps.enable = true;
    services.gnome.games.enable = true;
    services.gnome.core-developer-tools.enable = true;

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
