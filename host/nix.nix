{ ... }:

{
  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://mirror.sjtu.edu.cn/nix-channels/store"
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;
}
