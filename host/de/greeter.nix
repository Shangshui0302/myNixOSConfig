{ pkgs, ... }:

{
  # No display manager — pure TTY login with kmscon (DRM/KMS, full CJK via pango).
  # TTY1 login → howdy face unlock → shell → uwsm start <compositor>.
  # GNOME is isolated to a specialisation variant (with GDM).
  services.displayManager.sddm.enable = false;
  services.xserver.displayManager.lightdm.enable = false;
  services.greetd.enable = false;

  services.kmscon = {
    enable = true;
    config = {
      font-name = "Sarasa Mono SC";
      font-size = "24";
      hwaccel = true;
      # 关键：kmscon v10 默认启用 libseat，会以 root 的 greeter session 占住 VT，
      # 导致 pam_systemd 无法创建用户 session，uwsm 找不到 session → 无法启动 compositor。
      # libseat=false 走 raw VT 模式（Debian #1139666 官方 workaround），
      # 模块会自动清掉 User=root / PAMName=，把 session 创建交还给 login 的 PAM。
      libseat = false;
    };
  };
  fonts.packages = [ pkgs.sarasa-gothic ];
}
