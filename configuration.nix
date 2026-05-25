# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs,... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./litellm.nix
    ];

  ####################################
  #
  #------SYSTEM CONFIG---------------
  #
  ####################################
 
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  systemd.settings.Manager = {
    DefaultsTimeoutStopSec = 15;
  };
  
  # /boot security setting
  fileSystems."/boot" = {
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # Set network hostname
  networking.hostName = "MechRevo-NixOS"; 
  
  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  
  # Select internationalisation properties.
  i18n.defaultLocale = "zh_CN.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  # useXkbConfig = true; # use xkb.options in tty.
  };

  # 输入法配置
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      (fcitx5-rime.override {
        rimeDataPkgs = [
	  rime-ice
	  rime-moegirl
	  rime-zhwiki
	];
      })
      # fcitx5-pinyin-moegirl # 萌娘百科词库
      # fcitx5-pinyin-zhwiki  # 维基百科词库
      fcitx5-gtk            
      qt6Packages.fcitx5-chinese-addons
      qt6Packages.fcitx5-configtool
      fcitx5-material-color
      catppuccin-fcitx5
      kdePackages.fcitx5-qt
    ];
  };

  environment.variables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    NIXOS_OZONE_WL = "1";
    EDITOR = "nvim";
    SUDO_EDITOR = "nvim";
    STEAM_FORCE_DESKTOPUI_SCALING = "1.5";
    ANTHROPIC_BASE_URL = "http://127.0.0.1:4000";
    ANTHROPIC_AUTH_TOKEN = "030222";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;


  # Enable the GNOME Desktop Environment.
  # services.displayManager.gdm.enable = true;
  # services.desktopManager.gnome.enable = true;
  

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";
  
  # Graphics driver
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs;[
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };
  # Force to use AMDGPU driver
  boot.initrd.kernelModules = [ "amdgpu" ];
  services.xserver.videoDrivers = [ "amdgpu" ];
  
  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
  };

  # Enable Bluetooth service
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true; # Auto boot when power-on
  };
  services.blueman.enable = true; # A GUI for Bluetooth manager
  
  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;
  
  # Power manage(TLP/Auto-cpufreq)
  services.thermald.enable = true;
  # services.auto-cpufreq.enable = true;conflict with power-profiles-deamon which is needed by noctalia

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  
  # SSD optimizer
  services.fstrim.enable = true; 
  ####################################
  #
  #------USER and PACKAGE-------------
  #
  ####################################
 
  # Configure nix mirror source
  nix.settings.substituters = [ 
    "https://cache.nixos.org"
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" 
  ];
 
  # Optimize nix command 
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.lishangshui = {
    isNormalUser = true;
    description = "Li Shangshui";
    extraGroups = [ "wheel" "networkmanager" "video"]; # Enable ‘sudo’ for the user.
  };
  nixpkgs.overlays = [
    (final: prev: {
      wechat = prev.wechat.overrideAttrs (old: {
        src = prev.fetchurl {
          url = "https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.AppImage";
          sha256 = "0grv6xv2r0sdhx7p10bgsmnqmq4yhfzldq7h32msp3k5g4b2y42z";
        };
      });
    })
  ];
  programs.firefox.enable = true;
  
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
  programs.steam = {
    enable = true;
  };

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
  
  services.udev.packages = [
    pkgs.stlink
    pkgs.openocd
  ];
  
  programs.neovim.enable = true;

  programs.git.enable = true;

  programs.foot = {
    enable = true;
    theme = "catppuccin-mocha";
  };

  programs.starship = {
    enable = true;
  };

  # Mihomo service
  services.mihomo = {
    enable = true;
    configFile = "/persist/mihomo/config.yaml";
    tunMode = true;
    webui = pkgs.metacubexd;
  };
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "Meta" ];
    checkReversePath = "loose";
    #allowedTCPPorts = [ 9090 ];
  };
  services.gvfs.enable = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
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
    dnsutils    # 提供 dig, nslookup
    iputils     # 提供 ping
    tcpdump     # 抓包神器，查流量去哪了必选
    mtr         # 路由追踪，看哪一跳丢包
    nmap        # 扫描端口
    iperf3      # 测速
    ethtool     # 查看网卡硬件状态
    iptables
    
    # 硬件查看
    pciutils    # lspci
    usbutils    # lsusb
    pkgs.tree-sitter
    ripgrep
    nix-index
  ];

  # Chinese fonts support
  fonts.packages = with pkgs;[
    wqy_zenhei
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    font-awesome
    nerd-fonts.zed-mono
  ];

  # Allow some UNFREE or CLOSESOURCE software
  # like some drivers
  nixpkgs.config.allowUnfree = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?

}
