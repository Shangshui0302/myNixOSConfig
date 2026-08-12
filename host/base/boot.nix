{ ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  systemd.settings.Manager.DefaultsTimeoutStopSec = 15;

  # /boot options intentionally override hardware-configuration.nix
  # (fmask/dmask 0077 vs auto-generated 0022) for stricter EFI permissions.
  # device is inherited from hardware-configuration.nix via merge.
  fileSystems."/boot" = {
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  boot.kernelModules = [ "ntfs3" ];
  # amdgpu.dcdebugmask=0x40000 (DC_DISABLE_CUSTOM_BRIGHTNESS_CURVE):
  #   禁用面板固件的非线性亮度曲线，恢复线性映射。
  #   本机 (Radeon 780M/amdgpu_bl1, max=65535) 该曲线增益 >1，输入 >~64650 时
  #   映射输出超过 16-bit 上限而回绕溢出为 0 → Noctalia 100% 亮度反而全黑。
  #   实测: set=64500→actual=65535 (触顶), set=64800→actual=0 (溢出)。
  #   注: 内核 amdgpu custom brightness curve 代码在 6.15-6.17 反复回归 (MAX_BL_LEVEL
  #   0-255↔0-65535 换算错位), 6.18/6.19 又有 RDNA3/4 硬挂起回归; 故用此位彻底绕开曲线,
  #   不依赖内核版本。
  boot.kernelParams = [ "amdgpu.dcdebugmask=0x40000" ];

  system.stateVersion = "25.11";
}
