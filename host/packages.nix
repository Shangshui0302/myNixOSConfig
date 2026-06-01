{ pkgs, ... }:

{
  ####################################
  #
  # Package Overlays
  #
  ####################################

  nixpkgs.overlays = [
    (final: prev: {
      wechat = prev.wechat.overrideAttrs (old: {
        src = prev.fetchurl {
          url = "https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.AppImage";
          sha256 = "0grv6xv2r0sdhx7p10bgsmnqmq4yhfzldq7h32msp3k5g4b2y42z";
        };
      });
    })
    # nvim-treesitter-legacy 已废弃，alias 到新版消除 eval warning
    (final: prev: {
      vimPlugins = prev.vimPlugins // {
        nvim-treesitter-legacy = prev.vimPlugins.nvim-treesitter;
      };
    })
    # nvchad 仍依赖已废弃的 nvim-treesitter-legacy，替换为新版
    (final: prev: {
      vimPlugins = prev.vimPlugins // {
        nvchad = prev.vimPlugins.nvchad.overrideAttrs (old: {
          dependencies = map
            (dep: if dep.pname == "nvim-treesitter-legacy" then final.vimPlugins.nvim-treesitter else dep)
            (old.dependencies or []);
        });
      };
    })
  ];

  ####################################
  #
  # System Programs
  #
  ####################################

  programs.firefox.enable = true;

  programs.steam.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    stdenv.cc.cc.lib
    zlib
    glib
    libGL
    freetype
    libX11
    fontconfig
    fuse3
    icu
    nss
    openssl
    curl
    expat
    libgcc
  ];

  programs.direnv.enable = true;
  programs.neovim.enable = true;
  programs.git.enable = true;
  programs.starship.enable = true;

  programs.foot = {
    enable = true;
    theme = "catppuccin-mocha";
  };

  ####################################
  #
  # System Packages
  #
  ####################################

  environment.systemPackages = with pkgs; [
    neovim
    wget
    curl
    yazi
    ouch
    p7zip
    unzip
    file-roller
    nemo
    xarchiver

    # 网络诊断
    dnsutils
    iputils
    tcpdump
    mtr
    nmap
    iperf3
    ethtool
    iptables

    # 硬件查看
    pciutils
    usbutils

    tree-sitter
    ripgrep
    nix-index
  ];
}
