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

  xdg.configFile."ghostty/config.ghostty".text = ''
    scrollback-limit = 10000
    theme = MyGhostty Dark

    keybind = ctrl+shift+c=copy_to_clipboard
    keybind = ctrl+shift+v=paste_from_clipboard
    keybind = ctrl+plus=increase_font_size:1
    keybind = ctrl+minus=decrease_font_size:1
    keybind = ctrl+digit_0=reset_font_size
    keybind = ctrl+shift+i=inspector:toggle
    keybind = ctrl+shift+f=start_search
    keybind = ctrl+shift+page_up=jump_to_prompt:-1
    keybind = ctrl+shift+page_down=jump_to_prompt:1
    keybind = ctrl+shift+p=toggle_command_palette

    keybind = ctrl+shift+e=unbind
    keybind = ctrl+shift+o=unbind
    keybind = ctrl+shift+enter=unbind
    keybind = super+ctrl+shift+down=unbind
    keybind = super+ctrl+shift+left=unbind
    keybind = super+ctrl+shift+right=unbind
    keybind = super+ctrl+shift+up=unbind
    keybind = super+ctrl+shift+j=unbind
    keybind = ctrl+alt+shift+j=unbind
    keybind = super+ctrl+[=unbind
    keybind = super+ctrl+]=unbind
    keybind = ctrl+alt+down=unbind
    keybind = ctrl+alt+left=unbind
    keybind = ctrl+alt+right=unbind
    keybind = ctrl+alt+up=unbind

    keybind = alt+1=unbind
    keybind = alt+2=unbind
    keybind = alt+3=unbind
    keybind = alt+4=unbind
    keybind = alt+5=unbind
    keybind = alt+6=unbind
    keybind = alt+7=unbind
    keybind = alt+8=unbind
    keybind = alt+9=unbind
    keybind = alt+digit_1=unbind
    keybind = alt+digit_2=unbind
    keybind = alt+digit_3=unbind
    keybind = alt+digit_4=unbind
    keybind = alt+digit_5=unbind
    keybind = alt+digit_6=unbind
    keybind = alt+digit_7=unbind
    keybind = alt+digit_8=unbind
    keybind = alt+digit_9=unbind
    keybind = ctrl+shift+t=unbind
    keybind = ctrl+shift+w=unbind
    keybind = ctrl+shift+n=unbind
    keybind = ctrl+shift+tab=unbind
    keybind = ctrl+shift+left=unbind
    keybind = ctrl+shift+right=unbind
    keybind = ctrl+tab=unbind
    keybind = ctrl+page_down=unbind
    keybind = ctrl+page_up=unbind

    keybind = shift+end=unbind
    keybind = shift+home=unbind
    keybind = shift+page_down=unbind
    keybind = shift+page_up=unbind
    keybind = shift+down=unbind
    keybind = shift+left=unbind
    keybind = shift+right=unbind
    keybind = shift+up=unbind
    keybind = ctrl+shift+a=unbind

    keybind = ctrl+enter=unbind
    keybind = ctrl+shift+q=unbind
    keybind = ctrl+shift+j=unbind
    keybind = alt+f4=unbind
    keybind = ctrl+comma=ignore
    keybind = escape=unbind

    keybind = ctrl+insert=unbind
    keybind = shift+insert=unbind
    keybind = copy=unbind
    keybind = paste=unbind
  '';

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
