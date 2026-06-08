{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    eza zoxide fzf bat fd blesh
  ];

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;
      command_timeout = 2000;

      format = "$os $username$hostname $directory $git_branch$git_status$git_metrics $nix_shell $python $nodejs $rust $docker_context$line_break$time $battery $cmd_duration$line_break$character";
      line_break = "\n";

      os = {
        disabled = false;
        style = "#5277c3 bold";
        format = "[$symbol]($style)";
        symbols = {
          NixOS = "󱄅";
          Linux = "";
        };
      };

      username = {
        show_always = true;
        style_user = "#abe15b bold";
        style_root = "#ff2740 bold";
        format = "[$user]($style)[@](dimmed white)";
      };

      hostname = {
        ssh_only = false;
        style = "#5fafd7 bold";
        format = "[$hostname]($style)";
        trim_at = ".local";
      };

      directory = {
        style = "#33adff bold";
        read_only = "󰌾";
        read_only_style = "#ff2740";
        truncation_length = 4;
        truncate_to_repo = true;
        format = "[📁$path]($style)[$read_only]($read_only_style)";
        home_symbol = "~";
      };

      git_branch = {
        symbol = "";
        style = "#bb88ee bold";
        format = "[$symbol$branch(:$remote_branch)]($style)";
        truncation_length = 20;
        truncation_symbol = "…";
      };

      git_status = {
        style = "#ffd242 bold";
        format = "([$all_status$ahead_behind]($style)[/](#ffffff))";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        conflicted = "=\${count}";
        untracked = "?\${count}";
        stashed = "󰏗\${count}";
        modified = "!\${count}";
        staged = "+\${count}";
        renamed = "»\${count}";
        deleted = "✘\${count}";
      };

      git_metrics = {
        disabled = false;
        added_style = "#abe15b bold";
        deleted_style = "#ff2740 bold";
        format = "([+$added]($added_style)[/](#ffffff)[-$deleted]($deleted_style))";
        only_nonzero_diffs = true;
      };

      nix_shell = {
        symbol = "󱄅";
        style = "#5277c3 bold";
        format = "[$symbol $state]($style)";
        impure_msg = "[impure](#ff2740 bold)";
        pure_msg = "[pure](#abe15b bold)";
        unknown_msg = "[?](#ffd242 bold)";
      };

      python = {
        symbol = "󰌠";
        style = "#ffd242 bold";
        format = "[$symbol $version( \\($virtualenv\\))]($style)";
        python_binary = [ "python3" "python" ];
      };

      nodejs = {
        symbol = "";
        style = "#abe15b bold";
        format = "[$symbol $version]($style)";
      };

      rust = {
        symbol = "󱘗";
        style = "#ff2740 bold";
        format = "[$symbol $version]($style)";
      };

      docker_context = {
        symbol = "󰡨";
        style = "#0092ff bold";
        format = "[$symbol $context]($style)";
        only_with_files = true;
      };

      cmd_duration = {
        min_time = 2000;
        style = "#ffd242 bold";
        format = "[$duration]($style)";
        show_milliseconds = false;
      };

      time = {
        disabled = false;
        style = "#cccccc bold";
        format = "[󰥔 $time]($style)";
        time_format = "%H:%M";
      };

      battery = {
        disabled = false;
        full_symbol = "󰁹";
        charging_symbol = "󰂄";
        discharging_symbol = "󰂃";
        unknown_symbol = "󰁽";
        empty_symbol = "󰂎";

        display = [
          { threshold = 20; style = "#ff2740 bold"; }
          { threshold = 50; style = "#ffd242 bold"; }
          { threshold = 100; style = "#abe15b bold"; }
        ];
      };

      character = {
        success_symbol = "[❯](#abe15b bold)";
        error_symbol = "[❯](#ff2740 bold)";
        vimcmd_symbol = "[❮](#ffd242 bold)";
      };
    };
  };

  programs.zellij = {
    enable = true;
    settings = {
      theme = "catppuccin-mocha";
    };
  };

  # ghostty 已切换到 foot
  /* xdg.configFile."ghostty/config.ghostty".text = ''
    scrollback-limit = 10000
    theme = MyGhostty Dark
    font-size = 14

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
  ''; */

  programs.bash = {
    enable = true;
    initExtra = ''
      # ble.sh — 语法高亮、自动补全、Fish 风格建议
      source ${pkgs.blesh}/share/blesh/ble.sh

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


  xdg.configFile."blesh/init.sh".text = ''
    # ble.sh color override — 内置命令不用红色
    ble-face command_builtin=fg=#abe15b
    ble-face command_file=fg=#33adff
    ble-face syntax_varname=fg=#ffd242
  '';

  programs.fish = {
    enable = true;
    plugins = [
      { name = "autopair"; src = pkgs.fishPlugins.autopair; }
      { name = "done"; src = pkgs.fishPlugins.done; }
      { name = "grc"; src = pkgs.fishPlugins.grc; }
      { name = "colored-man-pages"; src = pkgs.fishPlugins.colored-man-pages; }
    ];

    interactiveShellInit = ''
      # 从 /persist/secrets/ 加载环境变量（如果存在）
      if test -f /persist/secrets/litellm.env
        while read -l line
          if string match -qr '^\s*[A-Z_]+\s*=' -- "$line"
            set -l kv (string split -m 1 "=" -- "$line")
            set -l name (string trim -- $kv[1])
            set -gx $name (string trim -- $kv[2])
          end
        end < /persist/secrets/litellm.env
      end

      # zoxide
      zoxide init fish | source

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

      # fish 问候
      set -g fish_greeting
    '';
  };

  # darkman fish completions: services.darkman 不自动暴露给 fish，需手动链接
  xdg.configFile."fish/completions/darkman.fish".source = "${pkgs.darkman}/share/fish/vendor_completions.d/darkman.fish";
}
