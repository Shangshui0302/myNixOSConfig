{ config, pkgs, ... }:

{
  # Main variant: greetd + tuigreet on tty1; GNOME is isolated to its GDM specialisation.
  services.displayManager.sddm.enable = false;
  services.xserver.displayManager.lightdm.enable = false;

  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings = {
      default_session = {
        command = "${pkgs.coreutils}/bin/env LANG=en_US.UTF-8 ${pkgs.tuigreet}/bin/tuigreet --config /etc/tuigreet/config.toml";
        user = "greeter";
      };
    };
  };

  # Keep PAM's password prompt ASCII so it renders correctly on the TTY font.
  systemd.services.greetd.environment.LC_MESSAGES = "C";
  systemd.services.greetd.environment.LC_TIME = "C";

  environment.etc."tuigreet/config.toml".text = ''
    # tuigreet 0.11.1 预览配置
    #
    # 用法：
    #   tuigreet --mock --config /tmp/tuigreet-config.toml
    #
    # 说明：保留当前预览配置中的已有值；其余项目使用程序默认值。
    # 对于“默认未设置”的可选字符串/数字，保留为注释，避免把它们误变成
    # 一个实际覆盖值。修改这个文件不会改变 Nix 配置或正在运行的 greetd。

    # 多显示器输出覆盖。默认：空列表。
    outputs = []

    [general]
    # 是否启用调试日志。可选：true / false；默认：false。
    debug = false

    # 日志文件路径。仅在 debug = true 时有意义；默认：/tmp/tuigreet.log。
    log_file = "/tmp/tuigreet.log"

    [session]
    # 固定登录后执行的命令。默认：未设置，由会话菜单选择。
    # command = "niri-session"

    # Wayland 会话文件目录。当前预览配置已有值，保持不变。
    sessions_dirs = [ "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions" ]

    # X11 会话文件目录。当前为一个空列表，保持不变。
    xsessions_dirs = []

    # 非 X11 会话的包装命令。默认：未设置。
    # session_wrapper = "exec"

    # X11 会话的包装命令。默认值："startx /usr/bin/env"。
    xsession_wrapper = "startx /usr/bin/env"

    # 启动默认会话时额外传入的环境变量。默认：空列表。
    environments = []

    [display]
    # 是否显示当前时间。已有配置：开启。
    show_time = true

    # 时间的 strftime 格式。默认：未设置，由程序使用内置格式。
    # 示例："%Y-%m-%d %H:%M:%S"
    time_format = "%a %b %d %H:%M:%S"

    # 自定义欢迎语；与 issue 二选一。当前使用 greeting。
    greeting = "Welcome, Li Shangshui"

    # 是否显示登录容器标题。默认：true。
    show_title = true

    # 登录容器标题文字。默认：未设置，使用程序默认标题。
    # 只有 show_title = true 时才可见。
    # custom_title = "SHIMMER"

    # 是否显示 /etc/issue。当前关闭，使用上面的 greeting。
    issue = false

    # 是否显示电池百分比。默认：false。
    battery = false

    # issue/greeting 的对齐方式。可选：left / center / right；默认：center。
    align_greeting = "center"

    [remember]
    # 默认预填的用户名。默认：未设置。
    # default_user = "lishangshui"

    # 记住上次成功登录的用户名。已有配置：开启。
    username = true

    # 记住上次选择的会话。关闭，避免覆盖按用户保存的会话。
    session = false

    # 按用户分别记住会话。已有配置：开启。
    user_session = true

    [user_menu]
    # 是否启用用户选择菜单。关闭以规避 tuigreet 0.11.0 的重复
    # CreateSession 问题；当前保留记住用户名和按用户记住会话。
    enabled = false

    # 用户菜单显示的最小 UID。默认：1000。
    min_uid = 1000

    # 用户菜单显示的最大 UID。默认：60000。
    max_uid = 60000

    [secret]
    # 密码等秘密输入的显示方式。可选：hidden / characters；已有配置：hidden。
    mode = "hidden"

    # mode = "characters" 时使用的遮罩字符；默认："*"。
    # 当前 mode = "hidden"，此字段不会显示密码字符，但保留默认值供切换时使用。
    characters = "*"

    [layout]
    # 登录主容器宽度（字符数）。范围由终端可用宽度决定；默认：80。
    width = 40

    # 终端窗口四周的留白。默认效果：0 个字符。
    window_padding = 0

    # 主容器内部留白。默认效果：1 个字符（程序内部会加上边框所需的 1）。
    container_padding = 1

    # 每行提示之间的留白。默认效果：1 个字符。
    prompt_padding = 1

    [layout.widgets]
    # 时间组件位置。可选：default / top / bottom / hidden；默认：default。
    time_position = "default"

    # 状态栏位置。可选：default / top / bottom / hidden；默认：default。
    status_position = "default"

    # 电池组件左右位置。可选：left / right；默认：left。
    battery_position = "left"

    [layout.widgets.status_bar]
    # 是否显示 Esc 重置操作。默认：true。
    show_reset = true

    # 是否显示命令菜单操作（默认绑定 F2）。默认：true。
    show_command = true

    # 是否显示会话菜单操作（默认绑定 F3）。默认：true。
    show_session = true

    # 是否显示电源菜单操作（默认绑定 F12）。默认：true。
    show_power = true

    # 是否显示背景动画切换操作（默认绑定 F4）。默认：true。
    show_background = true

    # 是否显示当前会话/命令状态指示。默认：true。
    show_session_status = true

    # 是否显示 Caps Lock 状态指示。默认：true。
    show_caps_lock = true

    [power]
    # 自定义关机命令。默认：未设置，使用系统默认动作。
    # shutdown = "systemctl poweroff"

    # 自定义重启命令。默认：未设置，使用系统默认动作。
    # reboot = "systemctl reboot"

    # 是否用 setsid 脱离电源命令。已有配置：开启。
    use_setsid = true

    [keybindings]
    # 命令菜单使用的 F 键编号。可选：1–12；已有配置：F2。
    command = 2

    # 会话菜单使用的 F 键编号。可选：1–12；已有配置：F3。
    sessions = 3

    # 背景动画菜单使用的 F 键编号。可选：1–12；已有配置：F4。
    background = 4

    # 电源菜单使用的 F 键编号。可选：1–12；已有配置：F12。
    power = 12

    [theme]
    # 以下颜色可以使用 ratatui 颜色名（如 red、lightgreen、cyan），也可使用
    # 支持的十六进制颜色写法。未设置的字段会回退到默认主题。

    # 容器边框颜色。当前值：white。
    border = "white"

    # 基础文字颜色。当前值：white。
    text = "white"

    # 时间颜色。当前值：lightred。
    time = "lightred"

    # 容器背景颜色。当前值：black。
    container = "black"

    # 容器标题颜色。当前值：lightgreen。
    title = "lightgreen"

    # issue 或 greeting 文字颜色。当前值：white。
    greet = "white"

    # Username/Password 等提示文字颜色。当前值：lightgreen。
    prompt = "lightgreen"

    # 用户输入反馈颜色。当前值：red。
    input = "lightred"

    # 底部操作说明文字颜色。当前值：white。
    action = "white"

    # 底部操作对应的功能键颜色。当前值：lightgreen。
    button = "lightgreen"

    [background]
    # 背景动画类型。可选：none / doom / matrix；当前关闭：none。
    kind = "none"

    # 动画帧率。启用动画时默认：30；范围由终端性能决定。
    fps = 30

    [background.doom]
    # DOOM 火焰衰减控制。可选：1–9；越大火焰越高；默认：6。
    height = 6

    # 火焰横向抖动范围。可选：0–4；越大越宽；默认：2。
    spread = 2

    # 火焰顶部（较冷）颜色。默认：#9F2707。
    top_color = "#9F2707"

    # 火焰中间颜色。默认：#C78F17。
    middle_color = "#C78F17"

    # 火焰底部（最热）颜色。默认：#FFFFFF。
    bottom_color = "#FFFFFF"

    [background.matrix]
    # 数字雨头部颜色。默认：#CCFFCC。
    head_color = "#CCFFCC"

    # 数字雨头部后方高亮区域颜色。默认：#33FF66。
    bright_color = "#33FF66"

    # 数字雨尾部暗色。默认：#006622。
    dim_color = "#006622"

    # 数字雨长度下限（行数）。默认：6。
    min_length = 6

    # 数字雨长度上限（行数）。默认：18。
    max_length = 18

    # 数字雨速度下限（行/帧）。默认：0.30；越小越慢。
    min_speed = 0.30

    # 数字雨速度上限（行/帧）。默认：1.10。
    max_speed = 1.10

    # 每个字符每帧变换的概率。可选：0.0–1.0；0.0 关闭闪烁；默认：0.02。
    mutate_chance = 0.02

    # 多显示器输出配置。默认：空列表，即不覆盖 DRM 输出选择。
    # 添加 [[outputs]] 后，connector 必填，例如 DP-1 或 HDMI-A-1。
    # 同时最多标记一个 primary = true；enabled 默认 true。
    #
    # [[outputs]]
    # connector = "DP-1"
    # enabled = true
    # primary = true

    [terminal]
    # 固定终端列数。与 rows 必须同时设置，且都必须大于 0；默认：未设置。
    # cols = 160

    # 固定终端行数。与 cols 必须同时设置；默认：未设置。
    # rows = 45
  '';

  # greetd supplies its own PAM stack (`useDefaultRules = false`); add Howdy
  # before its login substack so face unlock remains available.
  security.pam.services.greetd.rules.auth.howdy = {
    control = "sufficient";
    modulePath = "${config.services.howdy.package}/lib/security/pam_howdy.so";
    order = config.security.pam.services.greetd.rules.auth.login.order - 10;
  };

  # 保留旧配置以便回退；启用 greetd 时不能让 kmscon 同时占用 tty1。
  # services.kmscon = {
  #   enable = true;
  #   config = {
  #     font-name = "Sarasa Mono SC";
  #     font-size = "24";
  #     hwaccel = true;
  #     libseat = false;
  #   };
  # };
}
