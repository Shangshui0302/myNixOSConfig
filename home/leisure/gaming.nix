{ pkgs, ... }:

# Bottles：管理 Windows 应用与 wineprefix 的前端。
#
# Bottles 在 nixpkgs 里是 buildFHSEnv 包装（multiArch = true）：程序自身和它下载的
# Wine/Proton runner 都在 FHS 沙箱里执行，所以既不需要 `steam-run` 再包一层，也不依赖
# programs.nix-ld（host/base/compat.nix 那个是裸二进制的兜底）。32 位依赖来自
# host/base/hardware.nix 的 hardware.graphics.enable32Bit。
let
  # Bottles 会调用宿主默认程序。FHS 默认隐藏 /etc/xdg；映射整个目录，
  # 同时保留通用、桌面专属 MIME 关联及其优先级，避免回退到 code.desktop。
  buildFHSEnvWithDesktop =
    args:
    pkgs.buildFHSEnv (
      args
      // {
        extraBwrapArgs = (args.extraBwrapArgs or [ ]) ++ [
          "--ro-bind-try /etc/xdg /etc/xdg"
        ];
      }
    );
in
{
  home.packages = with pkgs; [
    # Bottles 上游只支持 Flatpak；nixpkgs 保留了「非沙箱环境」的警告弹窗，
    # removeWarningPopup 打补丁去掉（nixpkgs#384555），功能不受影响。
    (bottles.override {
      removeWarningPopup = true;
      buildFHSEnv = buildFHSEnvWithDesktop;
    })

    # 宿主层单独给一份 MangoHud：Bottles 的 env 里已有，Steam 走
    # `mangohud %command%` 时需要用户 PATH 上这一份。
    mangohud
  ];
}
