{ config, pkgs, ... }:

{
  wayland.windowManager.niri = {
    enable = true;
    package = pkgs.niri;
    portalPackage = null;
    xwaylandSatellitePackage = null;
    checkConfig = true;
    extraConfig = ''
      // ===== Output =====
      // 2K 屏 2560x1600 @ scale 1.5（与 Hyprland 一致）
      output "eDP-1" {
          scale 1.5
      }

      // ===== Input =====
      input {
          keyboard {
              xkb {
                  layout "us"
                  options "caps:escape"
              }
          }
          touchpad {
              tap
              natural-scroll
          }
          // epic-mouse-v1 的 sensitivity -0.5 在 niri 没有逐设备等价项，
          // 暂不迁移（niri 只支持全局 accel-speed）
      }

      // ===== Layout =====
      layout {
          gaps 5

          // 默认焦点环，Phase 5 (matugen+stylix) 再接管配色
          focus-ring {
              width 2
              active-color "#7fc8ff"
              inactive-color "#505050"
          }
          border {
              off
              width 2
              active-color "#ffc87f"
              inactive-color "#505050"
          }

          // 默认新窗口宽度
          default-column-width { proportion 0.5; }
      }

      // 请求客户端省略 CSD（foot 默认 csd=preferred 会要 niri 画标题栏）。
      // 开启后 foot 无标题栏，用 focus-ring 表示焦点（与 Hyprland/Sway 一致）。
      // 副作用：foot 半透明背景在聚焦窗口下可能有渲染问题；需重启应用生效。
      prefer-no-csd

      // ===== Screenshot =====
      screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

      // ===== Noctalia shell =====
      // 由 systemd user service 拉起（graphical-session.target），此处不再 spawn。

      // ===== Window rules =====
      // 全局窗口圆角（与 Hyprland rounding=10 一致）。
      // geometry-corner-radius 让 focus-ring/border 跟随圆角，
      // clip-to-geometry 让窗口内容本身也切圆角。
      window-rule {
          geometry-corner-radius 10
          clip-to-geometry true
      }

      // 文件预览器浮动（与 Hyprland 的 windowrulev2 一致）
      window-rule {
          match app-id=r#"^(org\.gnome\.NautilusPreviewer|sushi)$"#
          open-floating true
      }

      // Noctalia bar：xray 静态 blur 会错误糊掉透明圆角/间隙，
      // 改用 realtime (non-xray) blur 精确跟随 bar 形状（毛玻璃）。
      // 实验性：窗口开合/拖动动画期间 blur 会暂时消失。
      layer-rule {
          match namespace=r#"^noctalia-(bar-.+|dock|panel|attached-panel|osd)$"#
          background-effect {
              xray false
              blur true
          }
      }

      // 常用窗口 realtime (non-xray) blur —— 真毛玻璃（跟随圆角形状）
      // 需要窗口半透明才可见（foot 需 background 带 alpha）
      window-rule {
          match app-id=r#"^(foot|org\.gnome\.Nautilus|obsidian)$"#
          background-effect {
              xray false
              blur true
          }
      }

      // ===== Keybinds =====
      // Mod = Super（TTY 下）。Hyprland 键位迁移，Noctalia 功能保留。
      binds {
          // ---- 启动应用（对应 Hyprland）----
          Mod+W  hotkey-overlay-title="Open a Terminal: foot" { spawn "foot"; }
          Mod+E  { spawn "nautilus"; }
          Mod+B  { spawn "google-chrome"; }
          Mod+N  { spawn-sh "foot -e nvim"; }
          Mod+O  { spawn "obsidian"; }

          // ---- Noctalia 面板（quickshell IPC，与 compositor 无关）----
          Mod+Space { spawn-sh "noctalia msg panel-toggle launcher"; }
          Mod+C     { spawn-sh "noctalia msg panel-toggle clipboard"; }
          Mod+K     { spawn-sh "noctalia msg panel-toggle control-center"; }
          Mod+Shift+Comma { spawn-sh "noctalia msg settings-toggle"; }
          Mod+Shift+D { spawn-sh "darkman toggle"; }

          // Niri 原生工作区总览（不经过 Noctalia）
          Mod+Tab   { toggle-overview; }

          // ---- 截图（复用 Hyprland 的 screenshot 脚本）----
          Print       { spawn-sh "screenshot screen"; }
          Shift+Print { spawn-sh "screenshot area"; }

          // ---- 媒体 / 亮度 ----
          XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%+"; }
          XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"; }
          XF86AudioMute        allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
          XF86AudioMicMute     allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }
          XF86MonBrightnessUp   allow-when-locked=true { spawn-sh "noctalia msg brightness-up"; }
          XF86MonBrightnessDown allow-when-locked=true { spawn-sh "noctalia msg brightness-down"; }

          // ---- 窗口管理（niri 默认 + 用户习惯）----
          Mod+Q repeat=false { close-window; }
          Mod+F { fullscreen-window; }
          Mod+Shift+F { maximize-column; }
          Mod+V { toggle-window-floating; }
          Mod+Shift+M { quit; }
          Mod+Shift+W { toggle-column-tabbed-display; }

          // 方向键：聚焦
          Mod+Left  { focus-column-left; }
          Mod+Right { focus-column-right; }
          Mod+Up    { focus-window-up; }
          Mod+Down  { focus-window-down; }
          Mod+Home  { focus-column-first; }
          Mod+End   { focus-column-last; }

          // 列操作：consume / expel（把窗口并入/移出当前列，tabbed 的配套操作）
          Mod+BracketLeft  { consume-or-expel-window-left; }
          Mod+BracketRight { consume-or-expel-window-right; }
          Mod+Comma  { consume-window-into-column; }
          Mod+Period { expel-window-from-column; }

          // 方向键：移动
          Mod+Ctrl+Left  { move-column-left; }
          Mod+Ctrl+Right { move-column-right; }
          Mod+Ctrl+Up    { move-window-up; }
          Mod+Ctrl+Down  { move-window-down; }

          // 工作区
          Mod+1 { focus-workspace 1; }
          Mod+2 { focus-workspace 2; }
          Mod+3 { focus-workspace 3; }
          Mod+4 { focus-workspace 4; }
          Mod+5 { focus-workspace 5; }
          Mod+6 { focus-workspace 6; }
          Mod+7 { focus-workspace 7; }
          Mod+8 { focus-workspace 8; }
          Mod+9 { focus-workspace 9; }
          Mod+0 { focus-workspace 10; }
          Mod+Ctrl+1 { move-column-to-workspace 1; }
          Mod+Ctrl+2 { move-column-to-workspace 2; }
          Mod+Ctrl+3 { move-column-to-workspace 3; }
          Mod+Ctrl+4 { move-column-to-workspace 4; }
          Mod+Ctrl+5 { move-column-to-workspace 5; }
          Mod+Ctrl+6 { move-column-to-workspace 6; }
          Mod+Ctrl+7 { move-column-to-workspace 7; }
          Mod+Ctrl+8 { move-column-to-workspace 8; }
          Mod+Ctrl+9 { move-column-to-workspace 9; }
          Mod+Ctrl+0 { move-column-to-workspace 10; }

          // 滚动切工作区（与 Hyprland Super+滚轮一致）
          Mod+WheelScrollUp   cooldown-ms=150 { focus-workspace-up; }
          Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }

          // 宽度调整（列宽）
          Mod+R { switch-preset-column-width; }
          Mod+Minus { set-column-width "-10%"; }
          Mod+Equal { set-column-width "+10%"; }

          // 高度调整（列内窗口高度）
          Mod+Shift+Minus { set-window-height "-10%"; }
          Mod+Shift+Equal { set-window-height "+10%"; }
          Mod+Ctrl+Shift+R { switch-preset-window-height; }

          // 中心化 / 扩展
          Mod+Ctrl+C { center-visible-columns; }
          Mod+Ctrl+F { expand-column-to-available-width; }

          // 显示快捷键覆盖
          Mod+Shift+Slash { show-hotkey-overlay; }
      }

      // stylix 配色注入（替代 Noctalia 模板）：focus-ring 颜色壁纸取色，与 foot 同源
      include optional=true "~/.config/niri/stylix-colors.kdl"
      // matugen 动态配色（壁纸取色）：stylix 之后 include，位置序覆盖；matugen 写该文件自动热载
      include optional=true "~/.config/niri/wallpaper-colors.kdl"
    '';
  };

  # stylix 配色注入：niri focus-ring 颜色壁纸取色（与 hyprland stylix-colors.lua 同机制）
  xdg.configFile."niri/stylix-colors.kdl".text = ''
    layout {
        focus-ring {
            active-color "${config.lib.stylix.colors.withHashtag.base0D}"
            inactive-color "${config.lib.stylix.colors.withHashtag.base03}"
        }
    }
  '';

  # 补全（跟随消费者）：包内 fish vendor 补全。
  xdg.configFile."fish/completions/niri.fish".source =
    "${pkgs.niri}/share/fish/vendor_completions.d/niri.fish";
}
