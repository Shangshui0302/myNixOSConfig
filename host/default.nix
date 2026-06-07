{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ../hardware-configuration.nix
    ./core.nix
    ./desktop.nix
    ./services.nix
    ./litellm.nix
    ./sddm.nix
  ];

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
  ];
}
