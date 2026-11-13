{ pkgs, ... }:

{
  wayland.windowManager.niri = {
    enable = true;
    package = pkgs.niri;
    portalPackage = null;
    xwaylandSatellitePackage = pkgs.xwayland-satellite;
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
          // 再按当前工作区的数字键返回上一个工作区；鼠标经过不改变焦点。
          workspace-auto-back-and-forth
          // epic-mouse-v1 的 sensitivity -0.5 在 niri 没有逐设备等价项，
          // 暂不迁移（niri 只支持全局 accel-speed）
      }

      // ===== Layout =====
      layout {
          gaps 5

          // 静态回退保留原生成色板，末尾的 Matugen 文件在运行时覆盖。
          focus-ring {
              width 2
              active-color "#4badba"
              inactive-color "#4badba"
          }
          border {
              off
              width 2
              active-color "#ffc87f"
              inactive-color "#505050"
          }

          // 对齐 Hyprland 的列宽意图，保留 niri 原生视口和单列居中。
          default-column-width { proportion 0.667; }
          preset-column-widths {
              proportion 0.33
              proportion 0.5
              proportion 0.67
              proportion 0.81
              proportion 0.96
          }
          center-focused-column "on-overflow"
          always-center-single-column
      }

      // 接近 Hyprland 的开合/移动节奏；手势、工作区和总览保留原生弹簧。
      // 不用 custom-shader 模拟 popin，也不模拟 Lua 伪平铺策略。
      animations {
          window-open {
              duration-ms 410
              curve "cubic-bezier" 0.23 1 0.32 1
          }
          window-close {
              duration-ms 149
              curve "linear"
          }
          window-movement {
              duration-ms 479
              curve "cubic-bezier" 0.23 1 0.32 1
          }
          window-resize {
              duration-ms 479
              curve "cubic-bezier" 0.23 1 0.32 1
          }
      }

      // 请求客户端省略 CSD（foot 默认 csd=preferred 会要 niri 画标题栏）。
      // 开启后 foot 无标题栏，用 focus-ring 表示焦点（与 Hyprland/Sway 一致）。
      // 副作用：foot 半透明背景在聚焦窗口下可能有渲染问题；需重启应用生效。
      prefer-no-csd

      // ===== Screenshot =====
      screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

      // Shell 由 shell-switcher-boot 恢复选择，此处不再 spawn。

      // ===== Window rules =====
      // 全局窗口圆角（与 Hyprland rounding=15 一致，二者都对齐 caelestia 屏幕边框内圆角 25-10=15）。
      // geometry-corner-radius 让 focus-ring/border 跟随圆角，
      // clip-to-geometry 让窗口内容本身也切圆角。
      window-rule {
          geometry-corner-radius 15
          clip-to-geometry true
          opacity 0.88
      }
      window-rule {
          match is-active=false
          opacity 0.82
      }
      // 新浮动窗口默认居中；不复制 Hyprland 专有的 animation/override 语法。
      window-rule {
          match app-id="^org\\.kde\\.polkit-kde-authentication-agent-1$"
          open-floating true
          opacity 0.96
      }


      // Only the compact search panel floats; the main results window stays tiled.
      window-rule {
          match app-id="^digup-shell$" title="^DigUp Search$"
          open-floating true
          open-focused true
          // Keep client-requested size, including height changes as results arrive.
          default-column-width {}
          default-window-height {}
          opacity 1.0
          geometry-corner-radius 0
          clip-to-geometry false
          border { off; }
          focus-ring { off; }
          shadow { off; }
      }

      // Noctalia 通过 ext-background-effect 提交随形状/动画变化的模糊区域。
      // 只选择 realtime (non-xray)；不要强制 blur true，否则客户端撤销区域后
      // niri 仍会模糊整个 layer 矩形（例如隐藏中的 dock）。
      layer-rule {
          match namespace=r#"^noctalia-(bar-.+|dock|panel|attached-panel|osd)$"#
          background-effect {
              xray false
          }
      }

      // 常用窗口 realtime (non-xray) blur —— 真毛玻璃（跟随圆角形状）
      // 需要窗口半透明才可见（foot 需 background 带 alpha）
      window-rule {
          match app-id=r#"^(foot|obsidian)$"#
          background-effect {
              xray false
              blur true
          }
      }

      // ===== Keybinds =====
      // Mod = Super（TTY 下）；共享动作按当前 Shell 分发。
      binds {
          // ---- 启动应用（对应 Hyprland）----
          Mod+W  hotkey-overlay-title="Open a Terminal: foot" { spawn "foot"; }
          Mod+E  { spawn "strata"; }
          Mod+B  { spawn "google-chrome"; }
          Mod+N  { spawn-sh "foot -e nvim"; }
          Mod+O  { spawn "obsidian"; }

          // ---- Shell 公共动作 ----
          Mod+Shift+Space repeat=false hotkey-overlay-title="DigUp 内容搜索" { spawn "digup-shell" "--toggle"; }
          Mod+Space hotkey-overlay-title="应用启动器" { spawn "desktop-shell-action" "launcher"; }
          Mod+C hotkey-overlay-title="剪贴板历史" { spawn "desktop-shell-action" "clipboard"; }
          Mod+Shift+C hotkey-overlay-title="剪贴板删除（Noctalia 清空历史）" { spawn "desktop-shell-action" "clipboard-delete"; }
          Mod+Alt+K hotkey-overlay-title="控制中心" { spawn "desktop-shell-action" "control"; }
          Mod+Comma hotkey-overlay-title="Shell 设置" { spawn "desktop-shell-action" "settings"; }
          Mod+Shift+L repeat=false hotkey-overlay-title="锁屏" { spawn "desktop-shell-action" "lock"; }
          Mod+Shift+D { spawn-sh "darkman toggle"; }

          // Caelestia 独有面板，Noctalia 下无对应动作。
          Mod+D hotkey-overlay-title="Dashboard（Caelestia）" { spawn "desktop-shell-action" "dashboard"; }
          Mod+A hotkey-overlay-title="侧栏（Caelestia）" { spawn "desktop-shell-action" "sidebar"; }
          Mod+Alt+L hotkey-overlay-title="会话菜单（Caelestia）" { spawn "desktop-shell-action" "session"; }
          Mod+Shift+W hotkey-overlay-title="Dashboard / OSD（Caelestia）" { spawn "desktop-shell-action" "showall"; }

          // Niri 原生工作区总览（不经过 Noctalia）
          Mod+Tab   { toggle-overview; }
          Mod+G     { toggle-overview; }

          // ---- niri 原生截图：保存到 screenshot-path 并复制到剪贴板 ----
          Print       { screenshot-screen; }
          Shift+Print { screenshot; }
          Mod+Shift+Print { screenshot; }

          // ---- 媒体 / 亮度 ----
          XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%+"; }
          XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"; }
          XF86AudioMute        allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
          XF86AudioMicMute     allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }
          XF86AudioPlay  { spawn "desktop-shell-action" "media-playpause"; }
          XF86AudioPause { spawn "desktop-shell-action" "media-playpause"; }
          XF86AudioNext  { spawn "desktop-shell-action" "media-next"; }
          XF86AudioPrev  { spawn "desktop-shell-action" "media-prev"; }
          XF86AudioStop  { spawn "desktop-shell-action" "media-stop"; }
          XF86MonBrightnessUp   allow-when-locked=true { spawn "desktop-shell-action" "brightness-up"; }
          XF86MonBrightnessDown allow-when-locked=true { spawn "desktop-shell-action" "brightness-down"; }

          // ---- 窗口管理（niri 默认 + 用户习惯）----
          Mod+Q repeat=false { close-window; }
          Mod+F { fullscreen-window; }
          Mod+Shift+F { maximize-column; }
          Mod+V { toggle-window-floating; }
          Mod+Shift+M { quit; }
          Mod+Ctrl+Shift+W { toggle-column-tabbed-display; }

          // 方向键：聚焦
          Mod+Left  { focus-column-left; }
          Mod+Right { focus-column-right; }
          Mod+Up    { focus-window-up; }
          Mod+Down  { focus-window-down; }
          Mod+H { focus-column-left; }
          Mod+J { focus-window-down; }
          Mod+K { focus-window-up; }
          Mod+L { focus-column-right; }
          Mod+Home  { focus-column-first; }
          Mod+End   { focus-column-last; }

          // 列操作：consume / expel（把窗口并入/移出当前列，tabbed 的配套操作）
          Mod+BracketLeft  { consume-or-expel-window-left; }
          Mod+BracketRight { consume-or-expel-window-right; }
          Mod+Ctrl+Comma { consume-window-into-column; }
          Mod+Period { expel-window-from-column; }

          // 方向键：移动
          // 左右仍按 niri 的列移动，避免脚本拆列重组。
          Mod+Shift+Left  { move-column-left; }
          Mod+Shift+Right { move-column-right; }
          Mod+Shift+Up    { move-window-up; }
          Mod+Shift+Down  { move-window-down; }

          Mod+Alt+Left  { swap-window-left; }
          Mod+Alt+Right { swap-window-right; }
          Mod+Alt+Up    { move-window-up; }
          Mod+Alt+Down  { move-window-down; }

          // 原生 set-window-width 同时适用于平铺列和浮动窗口。
          Mod+Ctrl+Left  { set-window-width "-50"; }
          Mod+Ctrl+Right { set-window-width "+50"; }
          Mod+Ctrl+Up    { set-window-height "-50"; }
          Mod+Ctrl+Down  { set-window-height "+50"; }

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
          // 数字仍是 niri 当前显示器的动态索引；只移动当前窗口并跟随。
          Mod+Shift+1 { move-window-to-workspace 1; }
          Mod+Shift+2 { move-window-to-workspace 2; }
          Mod+Shift+3 { move-window-to-workspace 3; }
          Mod+Shift+4 { move-window-to-workspace 4; }
          Mod+Shift+5 { move-window-to-workspace 5; }
          Mod+Shift+6 { move-window-to-workspace 6; }
          Mod+Shift+7 { move-window-to-workspace 7; }
          Mod+Shift+8 { move-window-to-workspace 8; }
          Mod+Shift+9 { move-window-to-workspace 9; }
          Mod+Shift+0 { move-window-to-workspace 10; }

          // 沿用 Hyprland 的数字宽度档位意图，按工作区比例而非固定屏幕像素。
          Mod+Ctrl+1 { set-window-width "10%"; }
          Mod+Ctrl+2 { set-window-width "20%"; }
          Mod+Ctrl+3 { set-window-width "30%"; }
          Mod+Ctrl+4 { set-window-width "40%"; }
          Mod+Ctrl+5 { set-window-width "50%"; }
          Mod+Ctrl+6 { set-window-width "60%"; }
          Mod+Ctrl+7 { set-window-width "70%"; }
          Mod+Ctrl+8 { set-window-width "80%"; }
          Mod+Ctrl+9 { set-window-width "90%"; }
          Mod+Ctrl+0 { set-window-width "100%"; }

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

          // 原生帮助在两个 Shell 下均可用。
          Mod+Shift+Slash { show-hotkey-overlay; }
      }

      // Matugen 动态覆盖焦点环配色；写入该文件后自动热载。
      include optional=true "~/.config/niri/wallpaper-colors.kdl"
    '';
  };

  # 补全（跟随消费者）：包内 fish vendor 补全。
  xdg.configFile."fish/completions/niri.fish".source =
    "${pkgs.niri}/share/fish/vendor_completions.d/niri.fish";
}
