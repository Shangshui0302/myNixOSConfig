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
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  outputs =
    { nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "anthropic-fonts" ];
      };
      # 共享主题包：host（GNOME Shell 主题）+ home（GTK4 跟随）共用，参数集中在此一处。
      materialGnomeTheme = import ./local-deriv/material-gnome-theme.nix {
        inherit pkgs;
        wallpaper = ./assets/nixos_logo.png;
        shellLayout = "default"; # GNOME 原版实心通栏
      };
      materialAdwTheme = import ./local-deriv/material-adw-kvantum.nix { inherit pkgs; };
    in
    {
      packages.${system} = {
        material-gnome-theme = materialGnomeTheme;
        material-adw-kvantum = materialAdwTheme;
        animeko = pkgs.callPackage ./local-deriv/animeko.nix { };
        anthropic-fonts = import ./local-deriv/anthropic-fonts.nix { inherit pkgs; };
        cc-switch = import ./local-deriv/cc-switch.nix { inherit pkgs; };
        cliamp = import ./local-deriv/cliamp.nix { inherit pkgs; };
        scrolloverview = import ./local-deriv/hyprland-scroll-overview.nix { inherit pkgs; };
        netease-cloud-music-web-player = import ./local-deriv/netease-cloud-music-web-player.nix {
          inherit pkgs;
        };
      };

      devShells.${system}.packaging = pkgs.mkShellNoCC {
        packages = with pkgs; [
          binutils
          deadnix
          desktop-file-utils
          file
          fontconfig
          nix-init
          nix-update
          nixfmt
          nurl
          patchelf
          statix
        ];
      };

      nixosConfigurations."MechRevo-NixOS" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs materialGnomeTheme materialAdwTheme;
        };
        modules = [
          ./host/default.nix
          inputs.sops-nix.nixosModules.sops
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-backup";
              users.lishangshui = import ./home/home.nix;
              extraSpecialArgs = {
                inherit inputs materialGnomeTheme materialAdwTheme;
              };
            };
          }
        ];
      };
    };
}
