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
      url = "path:/home/lishangshui/Projects/shell-switcher"; # 托管 GitHub 后改 url
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, ... }@inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    # 共享主题包：host（GNOME Shell 主题）+ home（GTK4 跟随）共用，参数集中在此一处。
    materialGnomeTheme = import ./local-deriv/material-gnome-theme.nix {
      inherit pkgs;
      wallpaper = ./assets/yamadaryou.png;
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
          home-manager.backupFileExtension = "backup";
          home-manager.users.lishangshui = import ./home/hyprland.nix;
          home-manager.extraSpecialArgs = { inherit inputs materialGnomeTheme; };
        }
      ];
    };
  };
}
