{ pkgs, ... }:

{
  programs.zellij = {
    enable = true;
    settings = {
      theme = "catppuccin-mocha";
    };
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      # Starship prompt
      eval "$(starship init bash)"

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
    '';
  };
}
