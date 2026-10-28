{ ... }:

{
  nix.settings.substituters = [
    "https://cache.nixos.org/"
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store/"
    "https://mirrors.ustc.edu.cn/nix-channels/store/"
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  # Zotero 10 仍依赖 ESR 140；仅放行锁定的运行时版本，升级引擎后移除此例外。
  nixpkgs.config.permittedInsecurePackages = [
    "firefox-esr-140-bin-unwrapped-140.17.0esr"
  ];

  programs.nh = {
    enable = true;
    flake = "/home/lishangshui/myNixOSConfig";
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 10 --keep-since 7d";
    };
  };
}
