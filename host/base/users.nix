{ ... }:

{
  users.users.lishangshui = {
    isNormalUser = true;
    description = "Li Shangshui";
    linger = true;
    extraGroups = [ "wheel" "networkmanager" "video" "dialout" ];
  };

  security.sudo.extraRules = [
    {
      users = [ "lishangshui" ];
      commands = [
        { command = "/run/current-system/sw/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/nix";           options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/tee";           options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/chmod";         options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/chown";         options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/install";       options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/mv";            options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/cp";            options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/rm";            options = [ "NOPASSWD" ]; }
      ];
    }
  ];
}
