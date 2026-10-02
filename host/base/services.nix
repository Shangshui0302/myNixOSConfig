{ pkgs, ... }:

{
  security.rtkit.enable = true;
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.noctalia.greeter.apply-appearance" &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';
  services.flatpak.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.printing.enable = true;

  # 三档（power-saver / balanced / performance）电源管理已改由 TLP 接管：
  # 档位映射与开关在 host/base/tlp.nix（powerTlp.*），ppd 的启用/关闭也归它管
  # （TLP 提供 ppd 兼容的 D-Bus 接口，两者不能同时开）。
  services.upower.enable = true;

  services.fstrim.enable = true;

  services.howdy = {
    enable = true;
    settings = {
      core = {
        device_path = "/dev/video2";
      };
      video = {
        dark_threshold = 100;
        device_format = "v4l2";
      };
    };
  };

  security.pam.services = {
    sudo.howdy = { enable = true; control = "sufficient"; };
    su.howdy = { enable = true; control = "sufficient"; };
    login.howdy = { enable = true; control = "sufficient"; };
    greetd.howdy = { enable = true; control = "sufficient"; };
    noctalia.howdy = { enable = true; control = "sufficient"; };
  };

  services.gvfs.enable = true;

  # bubblewrap 供 Strata（local-deriv/strata.nix）的预览沙箱使用：它按固定系统目录
  # （/run/current-system/sw/bin 等）解析 bwrap、不读 PATH，所以必须进系统 profile。
  environment.systemPackages = with pkgs; [ ntfs3g bubblewrap ];

  boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;
}
