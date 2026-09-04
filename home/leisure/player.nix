{ pkgs, ... }:

let
  animeko = import ../../local-deriv/animeko.nix { inherit pkgs; };
  cliamp = import ../../local-deriv/cliamp.nix { inherit pkgs; };
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

  xdg.dataFile."icons/hicolor/256x256/apps/animeko.png".source = animeko.passthru.icon;

  xdg.desktopEntries.animeko = {
    name = "Animeko";
    comment = "集找番、追番、看番的一站式弹幕追番平台";
    exec = "animeko";
    icon = "animeko";
    terminal = false;
    categories = [
      "AudioVideo"
      "Player"
      "Video"
    ];
  };

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
