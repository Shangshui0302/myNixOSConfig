{
  description = "MechRevo-NixOS configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Track upstream sources without importing their separate Hyprland/toolchains.
    scrolloverview-src = {
      # Keep the last revision before decoration hooks: Hyprland 0.57
      # misrelocates renderRect's short branch and crashes in the new hook.
      url = "github:yayuuu/hyprland-scroll-overview/a8dcca6fe3ddc2164774cb6925bc67c0b974a78f";
      flake = false;
    };
    hypr-dynamic-cursors-src = {
      url = "github:VirtCode/hypr-dynamic-cursors/main";
      flake = false;
    };
    nextkde = {
      # Includes the post-v0.1.1 Nix module/deployment fixes; upgrades are explicit.
      url = "github:NextKde/NextKde/3fa1d7006869bbd3404a05d362c6e6028e0fe3da";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Temporary consumer of the tested package in nixpkgs PR #570118.
    # Use pkgs.strata and remove this input once our official channel includes it.
    strata-nixpkgs.url = "github:Shangshui0302/nixpkgs?ref=feature/strata";
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
    codex-desktop-linux = {
      url = "github:ilysenko/codex-desktop-linux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    shell-switcher = {
      url = "github:Shangshui0302/shell-switcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fcitx5-matugen-theme = {
      url = "github:Shangshui0302/fcitx5-mellow-themes-matugen";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wetypex = {
      url = "github:panxuc/fcitx5-wetypex";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
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
        config.allowUnfree = true;
      };
      # GTK3/4 主题基础供 Matugen 使用；不安装 GNOME Shell 主题。
      materialGnomeTheme = import ./local-deriv/material-gnome-theme.nix {
        inherit pkgs;
        wallpaper = ./assets/nixos_logo.png;
      };
      agentOrchestrator = pkgs.callPackage ./local-deriv/agent-orchestrator.nix { };
    in
    {
      packages.${system} = {
        nextkde-shell = pkgs.callPackage ./local-deriv/nextkde-shell.nix {
          src = inputs.nextkde;
          buildWeather = true;
        };
        nextkde = inputs.self.packages.${system}.nextkde-shell;
        nextkde-apps = pkgs.callPackage ./local-deriv/nextkde-apps.nix {
          src = inputs.nextkde;
        };
        nextkde-sync-shell = pkgs.callPackage ./local-deriv/nextkde-sync-shell.nix {
          kos = inputs.self.packages.${system}.nextkde-shell;
        };
        nextkde-platform-whitesur = pkgs.callPackage ./local-deriv/nextkde-platform-whitesur.nix {
          src = inputs.nextkde;
        };
        nextkde-spatial-models = pkgs.callPackage ./local-deriv/nextkde-spatial-models.nix { };
        nextkde-qdbus6 = pkgs.callPackage ./local-deriv/nextkde-qdbus6.nix { };
        nextkde-session-tools = pkgs.callPackage ./local-deriv/nextkde-session-tools.nix { };
        kmusic = pkgs.callPackage ./local-deriv/kmusic.nix { };
        # Upstream defaults; host/base/input-method.nix selects this host's options.
        fcitx5-wetypex = inputs.wetypex.packages.${system}.fcitx5-wetypex;
        agent-orchestrator = agentOrchestrator;
        agent-orchestrator-distrobox = pkgs.callPackage ./local-deriv/agent-orchestrator-distrobox.nix {
          inherit agentOrchestrator;
        };
        agentero = pkgs.callPackage ./local-deriv/agentero.nix { };
        herdr-app = pkgs.callPackage ./local-deriv/herdr-app.nix { };
        herdr-core = pkgs.callPackage ./local-deriv/herdr-core.nix { };
        dsh-x = pkgs.callPackage ./local-deriv/dsh-x.nix { };
        mnemon = pkgs.callPackage ./local-deriv/mnemon.nix { };
        agent-reach = pkgs.callPackage ./local-deriv/agent-reach.nix { };
        opencli = pkgs.callPackage ./local-deriv/opencli.nix { };
        material-gnome-theme = materialGnomeTheme;
        modernz-mpv = pkgs.callPackage ./local-deriv/modernz.nix { };
        hypr-dynamic-cursors = import ./local-deriv/hypr-dynamic-cursors.nix {
          inherit pkgs;
          src = inputs.hypr-dynamic-cursors-src;
        };
        scrolloverview = import ./local-deriv/hyprland-scroll-overview.nix {
          inherit pkgs;
          src = inputs.scrolloverview-src;
        };
        netease-cloud-music-web-player = import ./local-deriv/netease-cloud-music-web-player.nix {
          inherit pkgs;
        };
        strata = inputs.strata-nixpkgs.legacyPackages.${system}.strata;
      };

      checks.${system} =
        (import ./checks {
          inherit pkgs;
          nextkdeSync = inputs.self.packages.${system}.nextkde-sync-shell;
        })
        // {
          # Actual compilation catches plugin API drift when Hyprland is upgraded.
          hyprland-scrolloverview = inputs.self.packages.${system}.scrolloverview;
          hyprland-dynamic-cursors = inputs.self.packages.${system}.hypr-dynamic-cursors;
        };

      formatter.${system} = pkgs.nixfmt;

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
          inherit inputs materialGnomeTheme;
        };
        modules = [
          ./host/default.nix
          inputs.sops-nix.nixosModules.sops
          inputs.home-manager.nixosModules.home-manager
          ./host/base/home-manager.nix
        ];
      };
    };
}
