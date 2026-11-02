{ ... }:
{
  # main（Hyprland/niri DE）：共享 base + 桌面会话集成。
  imports = [
    ./base/default.nix
    ./de/sessions.nix
    ./de/greeter.nix
  ];

  home-manager.users.lishangshui = import ../home/home.nix;

  specialisation.nextkde = {
    inheritParentConfig = false;
    configuration = import ./nextkde/default.nix;
  };
}
