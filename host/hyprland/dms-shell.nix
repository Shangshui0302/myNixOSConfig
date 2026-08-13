{ config, lib, pkgs, ... }:
{
  # DMS-shell（DankMaterialShell）——Hyprland 桌面 shell，与 Noctalia 互斥。
  # 两者都抢 org.freedesktop.Notifications DBus + 都画顶栏，不能同时跑。
  # 由 shell-switcher 运行时切换：默认 Noctalia（WantedBy=graphical-session.target 自动起），
  # `shell-switcher set dms` 停 Noctalia、起 DMS；`set noctalia` 切回。
  programs.dms-shell = {
    enable = true;
    # 裁剪暂时用不上的功能，省闭包（系统监控/动态主题/音频波形/日历事件）
    enableSystemMonitoring = false;
    enableDynamicTheming = false;
    enableAudioWavelength = false;
    enableCalendarEvents = false;
  };
  # DMS service 不自动拉起（wantedBy 置空），由 shell-switcher 手动启停，
  # 避免与 Noctalia 同时激活（DBus 冲突）。Noctalia 保持自动起作为默认 shell。
  # SuccessExitStatus=143：DMS 被 SIGTERM 停（128+15）时 systemd 会标 failed，视作正常退出。
  systemd.user.services.dms.wantedBy = lib.mkForce [ ];
  systemd.user.services.dms.serviceConfig.SuccessExitStatus = lib.mkForce "143";
}
