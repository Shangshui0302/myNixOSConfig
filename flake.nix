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
      inputs.noctalia-qs.follows = "noctalia-qs";
    };
    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations."MechRevo-NixOS" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./host/default.nix
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.lishangshui = import ./home/default.nix;
          home-manager.extraSpecialArgs = { inherit inputs; };
        }
        {
          nixpkgs.overlays = [
            (final: prev: {
              wechat = prev.wechat.overrideAttrs (old: {
                src = prev.fetchurl {
                  url = "https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.AppImage";
                  sha256 = "0grv6xv2r0sdhx7p10bgsmnqmq4yhfzldq7h32msp3k5g4b2y42z";
                };
              });
            })
            (final: prev: {
              vimPlugins = prev.vimPlugins // {
                nvim-treesitter-legacy = prev.vimPlugins.nvim-treesitter;
              };
            })
            (final: prev: {
              open-orpheus = prev.appimageTools.wrapType2 {
                pname = "open-orpheus";
                version = "0.13.1";
                src = prev.fetchurl {
                  url = "https://github.com/YUCLing/open-orpheus/releases/download/v0.13.1/Open.Orpheus-0.13.1-x64.AppImage";
                  sha256 = "0z0ns6fq30lmc63kwfkcgnrzvd3q38ynw4xyansy0pji0r3lj5f6";
                };
                extraPkgs = pkgs: with pkgs; [ ];
                meta = with prev.lib; {
                  description = "Open-source cross-platform Netease Cloud Music client";
                  homepage = "https://github.com/YUCLing/open-orpheus";
                  license = licenses.mit;
                  platforms = [ "x86_64-linux" ];
                };
              };

              yesplaymusic = prev.appimageTools.wrapType2 {
                pname = "yesplaymusic";
                version = "0.4.10";
                src = prev.fetchurl {
                  url = "https://github.com/qier222/YesPlayMusic/releases/download/v0.4.10/YesPlayMusic-0.4.10.AppImage";
                  sha256 = "0vi9zp79x6pkfsdj6962m8zghgzynbbmlmqr83vabk7an50mjgs2";
                };
                extraPkgs = pkgs: with pkgs; [ libxshmfence ];
                meta = with prev.lib; {
                  description = "High-quality third-party Netease Cloud Music player";
                  homepage = "https://github.com/qier222/YesPlayMusic";
                  license = licenses.mit;
                  platforms = [ "x86_64-linux" ];
                };
              };

              netease-cloud-music-web-player = prev.stdenv.mkDerivation rec {
                pname = "netease-cloud-music-web-player";
                version = "1.6.0";

                src = ./assets/netease-cloud-music-web-player-1.6.0.tar.gz;

                sourceRoot = ".";

                nativeBuildInputs = [ prev.makeWrapper ];

                installPhase = ''
                  mkdir -p $out/{bin,lib/${pname},share/{applications,icons/hicolor/scalable/apps}}

                  cp app.asar $out/lib/${pname}/
                  cp netease-cloud-music.svg $out/share/icons/hicolor/scalable/apps/

                  substitute netease-cloud-music-web-player.desktop \
                    $out/share/applications/${pname}.desktop \
                    --replace-fail "/usr/bin/${pname}" "${pname}" \
                    --replace-fail "Icon=netease-cloud-music" "Icon=netease-cloud-music"

                  makeWrapper ${prev.electron}/bin/electron $out/bin/${pname} \
                    --add-flags "$out/lib/${pname}/app.asar" \
                    --add-flags "--no-sandbox --disable-gpu-sandbox --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --password-store=basic" \
                    --set-default ELECTRON_FORCE_IS_PACKAGED 1
                '';

                meta = with prev.lib; {
                  description = "Unofficial NetEase Cloud Music web player desktop client";
                  homepage = "https://github.com/feng-yifan/Netease-Cloud-Music-Web-Player";
                  license = licenses.mit;
                  platforms = [ "x86_64-linux" ];
                };
              };
            })
          ];
        }
      ];
    };
  };
}
