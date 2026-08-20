{
  description = "MechRevo-NixOS configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    caelestia = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";
    llm-agents.url = "github:numtide/llm-agents.nix";
    codex-desktop-linux.url = "github:ilysenko/codex-desktop-linux";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    shell-switcher = {
      url = "github:Shangshui0302/shell-switcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fcitx5-matugen-theme = {
      url = "github:Shangshui0302/fcitx5-mellow-themes-matugen";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };
  outputs = { self, nixpkgs, ... }@inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    # 共享主题包：host（GNOME Shell 主题）+ home（GTK4 跟随）共用，参数集中在此一处。
    materialGnomeTheme = import ./local-deriv/material-gnome-theme.nix {
      inherit pkgs;
      wallpaper = ./assets/nixos_logo.png;
      shellLayout = "default"; # GNOME 原版实心通栏
    };
  in {
    packages.${system}.material-gnome-theme = materialGnomeTheme;

    nixosConfigurations."MechRevo-NixOS" = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs materialGnomeTheme; };
      modules = [
        ./host/default.nix
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-backup";
          home-manager.users.lishangshui = import ./home/de.nix;
          home-manager.extraSpecialArgs = { inherit inputs materialGnomeTheme; };
        }
      ];
    };
  };
}
