{ ... }:

{
  users.users.lishangshui = {
    isNormalUser = true;
    description = "Li Shangshui";
    linger = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "dialout"
    ];
  };

  security.sudo.extraConfig = ''
    Defaults env_keep += "XDG_RUNTIME_DIR WAYLAND_DISPLAY GDK_BACKEND"
  '';

  security.sudo.extraRules = [
    {
      users = [ "lishangshui" ];
      commands = [
        # 保留用户明确需要的系统重建入口；它仍授予完整的系统维护能力。
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
