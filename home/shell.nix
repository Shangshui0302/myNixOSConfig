{ pkgs, ... }:

{
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      add_newline = true;
      format = "$username$hostname$directory$git_branch$git_state$git_status$character";
      directory.style = "cyan bold";
      git_branch.style = "magenta bold";
      git_state.style = "yellow";
      git_status.style = "red";
      character = {
        success_symbol = "✔ ";
        error_symbol = "✖ ";
        vicmd_symbol = "❮ ";
      };
    };
  };

  programs.zellij = {
    enable = true;
    settings = {
      theme = "catppuccin-mocha";
    };
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      # zoxide 智能 cd
      eval "$(zoxide init bash)"

      # 别名
      alias ls='eza --icons=auto'
      alias ll='eza -l --icons=auto'
      alias la='eza -la --icons=auto'
      alias lt='eza -T --icons=auto'
      alias cat='bat'
      alias grep='rg'
      alias find='fd'
      alias top='btop'
      alias tree='eza -T --icons=auto'

      # GH token from persisted secret
      [ -f /persist/secrets/gh.env ] && export GH_TOKEN=$(cat /persist/secrets/gh.env)
    '';
  };
}
