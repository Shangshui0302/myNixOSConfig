{ config, lib, pkgs, ... }:

{
  # COSMIC — System76 桌面环境（自带 session 管理，不经 uwsm）
  # cosmic-greeter 默认不启用（services.displayManager.cosmic-greeter.enable=false），
  # 保持 kmscon 纯 TTY 登录；登录后 TTY 里手动 `start-cosmic`。
  services.desktopManager.cosmic = {
    enable = true;
  };

  # 排除不必要的服务包（orca 是屏幕阅读器，普通桌面不需要）
  environment.cosmic.excludePackages = [ pkgs.orca ];
}
