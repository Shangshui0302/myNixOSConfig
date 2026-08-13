{ config, lib, pkgs, ... }:
{
  # Persona-Quickshell — 纯 QML Hyprland shell 主题，由 shell-switcher 运行时切换。
  # 源码 local-deriv/persona-quickshell.nix 拷到 store，quickshell -c 加载目录。
  # 与其他 shell 互斥（都抢 org.freedesktop.Notifications DBus）；wantedBy 置空由 switcher 启停。
  systemd.user.services.persona = {
    Unit = {
      Description = "Persona Quickshell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/qs -c ${
          (import ../../local-deriv/persona-quickshell.nix { inherit pkgs; })}/share/persona-quickshell";
      # Persona 的 Resume.qml 用 QtMultimedia，quickshell 默认环境不带其 QML 模块，补 import path
      # 注意 Qt6 的 QML 模块在 lib/qt-6/qml（qt-6，非 qt6）
      Environment = [ "QML_IMPORT_PATH=${pkgs.qt6.qtmultimedia}/lib/qt-6/qml" ];
      Restart = "on-failure";
      RestartSec = 3;
      KillMode = "control-group";
    };
    Install = {
      WantedBy = lib.mkForce [ ];
    };
  };
}
