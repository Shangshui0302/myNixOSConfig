{ config, lib, pkgs, inputs, ... }:
{
  # caelestia-dots/shell — Hyprland 桌面 shell，与 Noctalia 互斥（都抢 org.freedesktop.Notifications DBus）。
  # 由 shell-switcher 运行时切换：默认 Noctalia，set caelestia 切到 caelestia。
  # 注：caelestia 强制 quickshell-git（git.outfoxxed.me 外部源），依赖面大（fish/ddcutil/brightnessctl/lm_sensors 等）。
  imports = [
    inputs.caelestia.homeManagerModules.default
  ];

  programs.caelestia = {
    enable = true;
    # Hyprland 的共享快捷键通过 caelestia CLI 调用 shell IPC。
    cli.enable = true;
    settings = {
      # 壁纸仍由 waypaper + Matugen 统一管理，避免 Caelestia 另起一套主题管线。
      background.wallpaperEnabled = false;

      # 与 Noctalia 保持相同的常用应用和空闲策略。
      general.apps = {
        terminal = [ "foot" ];
        explorer = [ "nautilus" ];
      };
      general.idle = {
        lockBeforeSleep = true;
        inhibitWhenAudio = true;
        inhibitWhenCharging = false;
        timeouts = [
          {
            timeout = 600;
            idleAction = "lock";
            inhibitWhenAudio = false;
            inhibitWhenCharging = false;
            respectInhibitors = true;
          }
          {
            timeout = 660;
            idleAction = "dpms off";
            returnAction = "dpms on";
          }
        ];
      };

      # 保留统一壁纸管线；Caelestia 自带的 scheme/wallpaper 动作会绕过 Matugen。
      launcher.actions = [
        {
          name = "Calculator";
          icon = "calculate";
          description = "Do simple math equations";
          command = [ "autocomplete" "calc" ];
          enabled = true;
          dangerous = false;
        }
        {
          name = "Wallpaper";
          icon = "image";
          description = "Open the wallpaper manager";
          command = [ "waypaper" ];
          enabled = true;
          dangerous = false;
        }
        {
          name = "Settings";
          icon = "settings";
          description = "Configure the shell";
          command = [ "caelestia" "shell" "nexus" "open" ];
          enabled = true;
          dangerous = false;
        }
        {
          name = "Shutdown";
          icon = "power_settings_new";
          description = "Shutdown the system";
          command = [ "poweroff" ];
          enabled = true;
          dangerous = true;
        }
        {
          name = "Reboot";
          icon = "cached";
          description = "Reboot the system";
          command = [ "reboot" ];
          enabled = true;
          dangerous = true;
        }
        {
          name = "Logout";
          icon = "exit_to_app";
          description = "Log out of the current session";
          command = [ "logout" ];
          enabled = true;
          dangerous = true;
        }
        {
          name = "Lock";
          icon = "lock";
          description = "Lock the current session";
          command = [ "loginctl" "lock-session" ];
          enabled = true;
          dangerous = false;
        }
        {
          name = "Sleep";
          icon = "bedtime";
          description = "Suspend then hibernate";
          command = [ "suspendThenHibernate" ];
          enabled = true;
          dangerous = false;
        }
      ];

      # 本机已启用 Howdy；没有指纹设备，不让 Caelestia 等待指纹。
      lock = {
        enableFprint = false;
        enableHowdy = true;
      };

      services = {
        weatherLocation = "Chengdu, China";
        useFahrenheit = false;
        useFahrenheitPerformance = false;
        useTwelveHourClock = false;
        audioIncrement = 0.02;
        brightnessIncrement = 0.05;
        maxVolume = 1.0;
        smartScheme = false;
      };

      paths.wallpaperDir = "${config.home.homeDirectory}/Pictures/Wallpapers";
    };
  };

  # caelestia service 不自动拉起（wantedBy 置空），由 shell-switcher 手动启停，
  # 避免与 Noctalia 同时激活（DBus 冲突）。
  systemd.user.services.caelestia.Install.WantedBy = lib.mkForce [ ];
}
