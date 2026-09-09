{ pkgs, ... }:

let
  animeko = pkgs.callPackage ../../local-deriv/animeko.nix { };
  cliamp = import ../../local-deriv/cliamp.nix { inherit pkgs; };
  modernz = pkgs.callPackage ../../local-deriv/modernz.nix { };
in
{
  home.packages = with pkgs; [
    loupe
    mpv
    ani-cli
    kazumi
    cliamp
    obs-studio
    (import ../../local-deriv/netease-cloud-music-web-player.nix { inherit pkgs; })
    animeko
    go-musicfox
  ];

  xdg.configFile."mpv/mpv.conf".text = ''
    osc=no
    border=no
    title-bar=no
  '';

  home.file.".config/mpv/scripts/modernz.lua".source = "${modernz}/share/mpv/scripts/modernz.lua";
  home.file.".config/mpv/fonts/modernz-icons.ttf".source = "${modernz}/share/fonts/modernz-icons.ttf";
  home.file.".config/mpv/script-opts/modernz-locale.json".source =
    "${modernz}/share/mpv/script-opts/modernz-locale.json";

  xdg.desktopEntries.musicfox = {
    name = "go-musicfox";
    genericName = "Terminal Music Player";
    comment = "网易云音乐命令行客户端";
    exec = "foot -e musicfox";
    icon = "terminal";
    terminal = false;
    categories = [
      "AudioVideo"
      "Audio"
      "Player"
    ];
  };

  # 补全（跟随消费者）：fish + bash。
  xdg.configFile."fish/completions/cliamp.fish".source =
    "${cliamp}/share/fish/vendor_completions.d/cliamp.fish";

  xdg.dataFile."bash-completion/completions/cliamp".source =
    "${cliamp}/share/bash-completion/completions/cliamp";
}
