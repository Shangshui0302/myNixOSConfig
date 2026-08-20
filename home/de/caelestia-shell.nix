{ config, lib, pkgs, inputs, ... }:

let
  # Caelestia 自动保存 shell.json；HM 的默认链接指向 Nix store，只能在服务启动前
  # 解引用成普通文件。下一次 HM 激活仍会重新生成声明式源文件。
  prepareCaelestiaConfig = pkgs.writeShellScript "caelestia-prepare-config" ''
    config_path=${lib.escapeShellArg "${config.xdg.configHome}/caelestia/shell.json"}
    if [ -L "$config_path" ]; then
      tmp="$config_path.next"
      ${pkgs.coreutils}/bin/cp --dereference "$config_path" "$tmp"
      ${pkgs.coreutils}/bin/chmod 0644 "$tmp"
      ${pkgs.coreutils}/bin/mv -f "$tmp" "$config_path"
    fi
  '';
in
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
      # Caelestia 原生毛玻璃：透明层由 shell 绘制，抽屉会同步启用 Hyprland blur。
      appearance.transparency = {
        enabled = true;
        base = 0.8;
        layers = 0.4;
      };

      # 壁纸仍由 waypaper + Matugen 统一管理，避免 Caelestia 另起一套主题管线。
      background.wallpaperEnabled = false;

      # 从 Caelestia 运行时 shell.json 同步的 bar 偏好。
      bar = {
        activeWindow = {
          compact = false;
          inverted = true;
        };
        clock = {
          background = false;
          showDate = true;
        };
        popouts.tray = true;
        statusIcons = [
          { enabled = true; id = "lockStatus"; }
          { enabled = true; id = "audio"; }
          { enabled = true; id = "microphone"; }
          { enabled = false; id = "kbLayout"; }
          { enabled = true; id = "network"; }
          { enabled = true; id = "bluetooth"; }
          { enabled = true; id = "battery"; }
        ];
        tray = {
          background = false;
          compact = true;
          recolour = false;
        };
        workspaces = {
          activeTrail = true;
          maxWindowIcons = 5;
          occupiedBg = true;
        };
      };

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
      launcher.enableDangerousActions = true;
      launcher.showOnHover = true;
      launcher.useFuzzy = {
        actions = true;
        apps = true;
        schemes = true;
        variants = true;
        wallpapers = true;
      };
      launcher.vimKeybinds = true;
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

  # shell.json 已纳入 Nix 声明；Caelestia 运行时会把它解引用成可写文件，
  # 下次 HM 激活直接覆盖该文件，不再生成会反复冲突的备份。
  xdg.configFile."caelestia/shell.json".force = true;

  # caelestia service 不自动拉起（wantedBy 置空），由 shell-switcher 手动启停，
  # 避免与 Noctalia 同时激活（DBus 冲突）。
  systemd.user.services.caelestia = {
    Install.WantedBy = lib.mkForce [ ];
    Service.ExecStartPre = prepareCaelestiaConfig;
  };
}
