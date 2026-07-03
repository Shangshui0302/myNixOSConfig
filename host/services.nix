{ ... }:

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
  services.blueman.enable = true;

  services.printing.enable = true;

  services.thermald.enable = true;
  services.power-profiles-daemon.enable = true;
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

  boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;
}
