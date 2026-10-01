{ osConfig, pkgs, ... }:

# Lutris / Bottles：跑 Windows 游戏与 wineprefix 的前端。
#
# 两者在 nixpkgs 里都是 buildFHSEnv 包装（multiArch = true）：程序自身和它们下载的
# Wine/Proton runner 都在 FHS 沙箱里执行，所以既不需要 `steam-run` 再包一层，也不依赖
# programs.nix-ld（host/base/compat.nix 那个是裸二进制的兜底）。32 位依赖来自
# host/base/hardware.nix 的 hardware.graphics.enable32Bit。
{
  # 用 HM 原生模块而不是 home.packages 里的裸包：它默认关掉 lutris 的 steamSupport
  # （否则 FHS env 里会再塞一整份 Steam），并把 wine/proton 以只读链接挂进
  # ~/.local/share/lutris/runners，让 nixpkgs 的 Proton-GE 取代 Lutris 自行下载的 runner。
  programs.lutris = {
    enable = true;

    # 必须与系统 programs.steam 用同一个 store path，否则两份 Steam 实例互相冲突。
    steamPackage = osConfig.programs.steam.package;

    # Lutris 的 MangoHud / Gamescope 开关只设环境变量，真正的程序得能被找到；
    # 显式放进 FHS env 比依赖继承下来的宿主 PATH 更稳。
    extraPackages = with pkgs; [
      mangohud # FPS / GPU / CPU 叠加层
      gamescope # 嵌套合成器（Lutris 的 Gamescope 开关）
      winetricks # 手工给 prefix 补依赖
      umu-launcher # 下面的 Proton-GE 走 UMU 启动
      gtk4
      libadwaita
      # ↑ nixpkgs 的 zenity 是 GTK4 + libadwaita 版，而 lutris 的 FHS env 只装了 zenity
      #   本身、没带这两个库，winetricks 的 GUI 会报
      #   "zenity: error while loading shared libraries: libadwaita-1.so.0"（nixpkgs#410677
      #   在本 revision 仍未修）。放 extraPackages（targetPkgs，仅 64 位）而不是
      #   extraLibraries（multiPkgs，会连带要求 i686 的 gtk4）。
    ];

    # 直接用 nixpkgs 打包的 Proton-GE（含 32 位），免去 Lutris 里手动下载 runner；
    # 代价是首次构建要下载这份固定输出（数百 MB）。
    protonPackages = [ pkgs.proton-ge-bin ];
  };

  home.packages = with pkgs; [
    # Bottles 上游只支持 Flatpak；nixpkgs 保留了「非沙箱环境」的警告弹窗，
    # removeWarningPopup 打补丁去掉（nixpkgs#384555），功能不受影响。
    (bottles.override { removeWarningPopup = true; })

    # 宿主层单独给一份 MangoHud：Lutris / Bottles 各自的 env 里已有，Steam 走
    # `mangohud %command%` 时需要用户 PATH 上这一份。
    mangohud
  ];
}
