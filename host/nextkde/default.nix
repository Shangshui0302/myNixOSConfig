{ inputs, ... }:
{
  # Independent Plasma system: only the shared base is inherited, not the main DE.
  imports = [
    ../base/default.nix
    inputs.sops-nix.nixosModules.sops
    inputs.home-manager.nixosModules.home-manager
    inputs.nextkde.nixosModules.kos
    ../base/home-manager.nix
    ./desktop.nix
  ];

  home-manager.users.lishangshui = import ../../home/nextkde.nix;
}
