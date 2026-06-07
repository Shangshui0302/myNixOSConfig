{ ... }:

{
  programs.git = {
    enable = true;
    settings.user.name = "Li Shangshui";
    settings.user.email = "yomuwaterray@gmail.com";
    ignores = [ "**/.claude/settings.local.json" ];
  };
}
