{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "Li Shangshui";
      user.email = "Shangshui0302@users.noreply.github.com";
      credential.helper = "!gh auth git-credential";
    };
  };
}
