{ ... }:

{
  programs.git = {
    enable = true;
    settings.user.name = "Li Shangshui";
    settings.user.email = "Shangshui0302@users.noreply.github.com";
    ignores = [ "**/.claude/settings.local.json" ];
  };
}
