{ config, pkgs, ... }:

let
  # 变体判据：当前仅两变体（main=Hyprland + gnome），"非 gnome 即 Hyprland" 是二元假设。
  # 若将来加第三个变体，需把此布尔泛化为显式变体标识（如 specialArgs 注入 variant 字符串）。
  gnome = config.services.desktopManager.gnome.enable;
in

{
  # 共享桌面基础（两 DE 都要）：keyring / 字体 / X server。

  # GNOME Keyring — 为 Electron/VS Code 类应用提供加密凭据存储
  services.gnome.gnome-keyring.enable = true;

  # 目录默认值与各变体已安装的文件管理器一致；保留用户层可写的其他 MIME 关联。
  # 不启用 HM 的整份 mimeapps.list 管理，避免顺带激活已有的文本默认值。
  xdg.mime.defaultApplications."inode/directory" =
    if gnome then "org.gnome.Nautilus.desktop" else "io.github.lgse.Strata.desktop";

  # 主桌面的手机互联；原生模块同时安装 KDE Connect 并开放发现所需端口。
  # GNOME 变体已有 GSConnect，避免同时运行两个 KDE Connect 协议实现。
  programs.kdeconnect.enable = !gnome;

  environment.variables = {
    EDITOR = "nvim";
    SUDO_EDITOR = "nvim";
    STEAM_FORCE_DESKTOPUI_SCALING = "2.0";
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GDK_SCALE = "2";
    GDK_BACKEND = "wayland";
  };

  # ── 无障碍（AT-SPI）+ Wayland 键盘注入 ────────────────────────────────────
  # DSH 的 computer-use（cua-driver 原生后端）靠 AT-SPI 读界面元素树；没有
  # org.a11y.Bus 时 health_report 的 ax_capability 会失败，只剩"整屏截图+坐标
  # 点击"。三件事必须齐：
  #   1) 模块：拉起 a11y 总线的 systemd 用户服务
  #   2) 模块的 services.dbus.packages：把 org.a11y.Bus 的激活服务文件注册进会话总线
  #   3) pathsToLink：下文把 /share/dbus-1 并进已有的 pathsToLink 行
  # wtype：Wayland 虚拟键盘注入器。cua-driver 自带键盘走 libei / portal
  # RemoteDesktop，而 xdg-desktop-portal-hyprland 未实现该接口（实测 20s 超时），
  # 故桌面键盘注入由 wtype 承担。已实测：wtype 打字 + Enter 提交，在健康的
  # fcitx5 输入上下文里可完整写入应用（含空格/数字/符号）。
  # 注意：系统 profile 在 distrobox 容器内不可见（/run/current-system 不存在），
  # 容器侧需按 /nix/store/*-wtype-*/bin/wtype 动态取用。
  services.gnome.at-spi2-core.enable = true;
  # 官方模块只做 systemd.packages（把单元链接进 /etc/systemd/user），并不启用它，
  # 单元状态是 "linked-runtime; preset: ignored" / inactive。而
  # org.a11y.Bus.service 是 SystemdService=at-spi-dbus-bus.service 的惰性激活，
  # dbus-broker 的用户实例不会替我们把它拉起来 —— 实测 D-Bus 激活拿不到名字，
  # 必须 systemctl --user start 才起。故显式加入 default.target（与同目录
  # gcr-ssh-agent.nix 的做法一致）。
  systemd.user.services.at-spi-dbus-bus.wantedBy = [ "default.target" ];
  environment.systemPackages = with pkgs; [ wtype ];

  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";

  # /share/dbus-1：AT-SPI 的 org.a11y.Bus 激活服务文件（默认 pathsToLink 白名单
  # 不含它，缺了则会话总线激活不了 a11y 总线 → cua-driver 的 ax_capability 失败）。
  environment.pathsToLink = [ "/share/dbus-1" ];

  # Fonts
  fonts.packages = with pkgs; [
    wqy_zenhei wqy_microhei
    noto-fonts-cjk-sans noto-fonts-cjk-serif
    source-han-serif source-han-sans

    inter source-serif
    noto-fonts-color-emoji
    lxgw-wenkai sarasa-gothic
    arphic-ukai arphic-uming
    eb-garamond libertine
    nerd-fonts.jetbrains-mono nerd-fonts.fira-code
    nerd-fonts.caskaydia-mono nerd-fonts.iosevka
    nerd-fonts.geist-mono nerd-fonts.monaspace
    nerd-fonts.zed-mono nerd-fonts.symbols-only
    font-awesome
  ];

  fileSystems."/usr/share/fonts" = {
    device = "/run/current-system/sw/share/X11/fonts";
    fsType = "bind";
    options = [ "bind" "ro" ];
  };

  services.libinput.enable = true;

  # 屏幕录制：gpu-screen-recorder 的 KMS helper 需要 cap_sys_admin 才能读 DRM。
  # 它的启动路径写死成 pkexec（二进制里就是 "pkexec" + 下面这条 setcap 提示），而 NixOS 的
  # setuid pkexec 仍会走 polkit 认证 —— 在 Hyprland 会话里会卡在 "waiting for server to
  # connect" 直到超时。所以直接按上游提示给 wrapper 加 cap_sys_admin+ep：helper 自带特权，
  # 不需要 pkexec、不需要认证。setuid 保留作为兜底。
  security.polkit.enablePkexecWrapper = true;
  security.wrappers."gsr-kms-server" = {
    source = "${pkgs.gpu-screen-recorder}/bin/gsr-kms-server";
    owner = "root";
    group = "root";
    # setuid 与 capabilities 互斥（wrapper 构建期校验），cap_sys_admin 这条路径不需要 setuid。
    capabilities = "cap_sys_admin+ep";
  };
}
