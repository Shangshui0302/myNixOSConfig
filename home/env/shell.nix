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

      format = "$os $username$hostname $directory $git_branch$git_status$git_metrics$nix_shell $python $nodejs $rust $docker_context$line_break$time $battery $cmd_duration$line_break$character";
      line_break = "\n";
      os = {
        disabled = false;
        style = "#5277c3 bold";
        format = "[$symbol]($style)";
        symbols = {
          NixOS = "";
          Linux = "";
          Arch = "";
          Ubuntu = "";
          Fedora = "";
          Debian = "";
        };
      };

      custom.distrobox = {
        when = "[ -n \"$DISTROBOX_ID\" ]";
        command = "echo $DISTROBOX_ID";
        style = "#ff88cc bold";
        format = "[📦 $output ]($style)";
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

      aws.symbol = " ";
      azure.symbol = " ";
      buf.symbol = " ";
      bun.symbol = " ";
      c.symbol = " ";
      cmake.symbol = " ";
      cobol.symbol = " ";
      conda.symbol = " ";
      container.symbol = " ";
      crystal.symbol = " ";
      dart.symbol = " ";
      deno.symbol = " ";
      dotnet.symbol = " ";
      elixir.symbol = " ";
      elm.symbol = " ";
      erlang.symbol = " ";
      fennel.symbol = " ";
      fortran.symbol = " ";
      fossil_branch.symbol = " ";
      gcloud.symbol = "󱇶 ";
      gleam.symbol = " ";
      golang.symbol = " ";
      gradle.symbol = " ";
      guix_shell.symbol = " ";
      haskell.symbol = " ";
      haxe.symbol = " ";
      helm.symbol = " ";
      hg_branch.symbol = " ";
      java.symbol = " ";
      julia.symbol = " ";
      kotlin.symbol = " ";
      kubernetes.symbol = "󱃾 ";
      lua.symbol = " ";
      maven.symbol = " ";
      meson.symbol = "󰔷 ";
      mojo.symbol = "󰈸 ";
      nats.symbol = " ";
      netns.symbol = "󰛳 ";
      nim.symbol = " ";
      ocaml.symbol = " ";
      odin.symbol = "󰟢 ";
      opa.symbol = " ";
      openstack.symbol = " ";
      package.symbol = "󰏗 ";
      perl.symbol = " ";
      php.symbol = " ";
      pijul_channel.symbol = " ";
      pixi.symbol = "󰏗 ";
      pulumi.symbol = " ";
      purescript.symbol = " ";
      raku.symbol = "󱖊 ";
      red.symbol = "󱍼 ";
      rlang.symbol = "󰟔 ";
      ruby.symbol = " ";
      scala.symbol = " ";
      shlvl.symbol = "󰹍 ";
      singularity.symbol = " ";
      solidity.symbol = " ";
      spack.symbol = " ";
      status.symbol = " ";
      sudo.symbol = " ";
      swift.symbol = " ";
      terraform.symbol = " ";
      typst.symbol = " ";
      vagrant.symbol = " ";
      vlang.symbol = " ";
      xmake.symbol = " ";
      zig.symbol = " ";

      git_branch = {
        symbol = "";
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
        modified = "![\${count}]($style)";
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
        symbol = "";
        style = "#5277c3 bold";
        format = "[$symbol $state]($style)";
        impure_msg = "[impure](#ff2740 bold)";
        pure_msg = "[pure](#abe15b bold)";
        unknown_msg = "[?](#ffd242 bold)";
      };

      python = {
        symbol = "";
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
        symbol = "";
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
        style = "#ffffff bold";
        format = "[󰥔 $time]($style)";
        time_format = "%H:%M";
      };

      battery = {
        disabled = false;
        full_symbol = "󰁹";
        charging_symbol = "󰂄";
        discharging_symbol = "󰂃";
        unknown_symbol = "󰂑";
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

  # ghostty 已切换到 foot，暂时禁用 ghostty
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

      # foot notification: 超过 10s 的命令完成后弹通知 (via ble.sh)
      blehook PREEXEC='_foot_start=$(date +%s); _foot_cmd=$1'
      blehook POSTEXEC='
        if [[ -n $_foot_start ]]; then
          dur=$(($(date +%s) - _foot_start))
          if (( dur >= 10 )); then
            printf "\\e]777;notify;%s;%s\\e\\\\" "$_foot_cmd" "Finished in "$dur"s"
          fi
          unset _foot_start _foot_cmd
        fi
      '

      alias snvim='sudo HOME=$HOME XDG_CONFIG_HOME=$XDG_CONFIG_HOME XDG_DATA_HOME=$XDG_DATA_HOME nvim'
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

      alias snvim='sudo HOME=$HOME XDG_CONFIG_HOME=$XDG_CONFIG_HOME XDG_DATA_HOME=$XDG_DATA_HOME nvim'

      # fish 问候
      set -g fish_greeting

      # foot notification: 超过 10s 的命令完成后弹通知
      set -g _foot_notify_threshold 10
      function _foot_preexec --on-event fish_preexec
          set -g _foot_start (date +%s)
          set -g _foot_cmd $argv
      end
      function _foot_postexec --on-event fish_postexec
          if not set -q _foot_start; return; end
          set -l dur (math (date +%s) - $_foot_start)
          if test $dur -ge $_foot_notify_threshold
              printf "\e]777;notify;%s;%s\e\\" \
                  "$_foot_cmd" \
                  "Finished in $(math round $dur)s"
          end
          set -e _foot_start
          set -e _foot_cmd
      end
    '';
  };

  xdg.configFile."fish/completions/hyprctl.fish".text = ''
    # Flags
    complete -c hyprctl -s j -d "Output in JSON"
    complete -c hyprctl -s r -d "Refresh state after issuing command"
    complete -c hyprctl -l batch -d "Execute batch of commands separated by ;"
    complete -c hyprctl -s i -l instance -d "Use a specific Hyprland instance" -x
    complete -c hyprctl -s q -l quiet -d "Disable output"

    # Commands (read-only)
    complete -c hyprctl -n "__fish_use_subcommand" -a activewindow     -d "Get active window name and properties"
    complete -c hyprctl -n "__fish_use_subcommand" -a activeworkspace  -d "Get active workspace and properties"
    complete -c hyprctl -n "__fish_use_subcommand" -a animations       -d "Get current animation/bezier config"
    complete -c hyprctl -n "__fish_use_subcommand" -a binds            -d "List all registered keybinds"
    complete -c hyprctl -n "__fish_use_subcommand" -a clients          -d "List all windows with properties"
    complete -c hyprctl -n "__fish_use_subcommand" -a configerrors     -d "List current config parsing errors"
    complete -c hyprctl -n "__fish_use_subcommand" -a cursorpos        -d "Get current cursor position in layout coords"
    complete -c hyprctl -n "__fish_use_subcommand" -a decorations      -d "List all decorations and info" -x
    complete -c hyprctl -n "__fish_use_subcommand" -a devices          -d "List all connected keyboards and mice"
    complete -c hyprctl -n "__fish_use_subcommand" -a globalshortcuts  -d "List all global shortcuts"
    complete -c hyprctl -n "__fish_use_subcommand" -a instances        -d "List all running Hyprland instances"
    complete -c hyprctl -n "__fish_use_subcommand" -a layers           -d "List all surface layers"
    complete -c hyprctl -n "__fish_use_subcommand" -a layouts          -d "List all available layouts"
    complete -c hyprctl -n "__fish_use_subcommand" -a monitors         -d "List active outputs with properties"
    complete -c hyprctl -n "__fish_use_subcommand" -a rollinglog       -d "Print tail of the log"
    complete -c hyprctl -n "__fish_use_subcommand" -a splash           -d "Get the current splash"
    complete -c hyprctl -n "__fish_use_subcommand" -a status           -d "Get internal status information"
    complete -c hyprctl -n "__fish_use_subcommand" -a systeminfo       -d "Get system info"
    complete -c hyprctl -n "__fish_use_subcommand" -a version          -d "Print Hyprland version"
    complete -c hyprctl -n "__fish_use_subcommand" -a workspacerules   -d "List all workspace rules"
    complete -c hyprctl -n "__fish_use_subcommand" -a workspaces       -d "List all workspaces with properties"

    # Commands (actions)
    complete -c hyprctl -n "__fish_use_subcommand" -a dismissnotify  -d "Dismiss notifications [amount]"
    complete -c hyprctl -n "__fish_use_subcommand" -a dispatch       -d "Call a keybind dispatcher with args" -x
    complete -c hyprctl -n "__fish_use_subcommand" -a getoption      -d "Get config option status" -x
    complete -c hyprctl -n "__fish_use_subcommand" -a keyword        -d "Set a config keyword dynamically" -x
    complete -c hyprctl -n "__fish_use_subcommand" -a kill           -d "Enter kill mode (click to close app)"
    complete -c hyprctl -n "__fish_use_subcommand" -a notify         -d "Send a built-in Hyprland notification" -x
    complete -c hyprctl -n "__fish_use_subcommand" -a output         -d "Add/remove fake outputs" -x
    complete -c hyprctl -n "__fish_use_subcommand" -a plugin         -d "Issue a plugin request" -x
    complete -c hyprctl -n "__fish_use_subcommand" -a reload         -d "Force reload config [config-only]"
    complete -c hyprctl -n "__fish_use_subcommand" -a setcursor      -d "Set cursor theme and size" -x
    complete -c hyprctl -n "__fish_use_subcommand" -a seterror       -d "Set hyprctl error string" -x
    complete -c hyprctl -n "__fish_use_subcommand" -a setprop        -d "Set a window property" -x
    complete -c hyprctl -n "__fish_use_subcommand" -a getprop        -d "Get a window property" -x
    complete -c hyprctl -n "__fish_use_subcommand" -a switchxkblayout -d "Set xkb layout index for keyboard" -x
  '';

  xdg.configFile."fish/completions/hyprland.fish".text = ''
    complete -c hyprland -s h -l help -d "Show help message"
    complete -c hyprland -s v -l version -d "Print version"
    complete -c hyprland -l version-json -d "Print version as JSON"
    complete -c hyprland -s c -l config -r -d "Specify config file to use"
    complete -c hyprland -l socket -x -d "Set Wayland socket name"
    complete -c hyprland -l wayland-fd -x -d "Set Wayland socket fd"
    complete -c hyprland -l safe-mode -d "Start in safe mode"
    complete -c hyprland -l systeminfo -d "Print system info"
    complete -c hyprland -l verify-config -d "Verify config and exit"
  '';

  xdg.configFile."fish/completions/podman.fish".text = ''
    function __podman_debug
        set -l file "$BASH_COMP_DEBUG_FILE"
        if test -n "$file"
            echo "$argv" >> $file
        end
    end

    function __podman_perform_completion
        set -l args (commandline -opc)
        set -l lastArg (string escape -- (commandline -ct))
        set -l requestComp "PODMAN_ACTIVE_HELP=0 $args[1] __complete $args[2..-1] $lastArg"
        set -l results (eval $requestComp 2> /dev/null)
        for line in $results[-1..1]
            if test (string trim -- $line) = ""
                set results $results[1..-2]
            else
                break
            end
        end
        set -l comps $results[1..-2]
        set -l directiveLine $results[-1]
        set -l flagPrefix (string match -r -- '-.*=' "$lastArg")
        for comp in $comps
            printf "%s%s\n" "$flagPrefix" "$comp"
        end
        printf "%s\n" "$directiveLine"
    end

    function __podman_perform_completion_once
        if test -n "$__podman_perform_completion_once_result"
            return 0
        end
        set --global __podman_perform_completion_once_result (__podman_perform_completion)
        if test -z "$__podman_perform_completion_once_result"
            return 1
        end
        return 0
    end

    function __podman_clear_perform_completion_once_result
        set --erase __podman_perform_completion_once_result
    end

    function __podman_requires_order_preservation
        __podman_perform_completion_once
        if test -z "$__podman_perform_completion_once_result"
            return 1
        end
        set -l directive (string sub --start 2 $__podman_perform_completion_once_result[-1])
        set -l shellCompDirectiveKeepOrder 32
        set -l keeporder (math (math --scale 0 $directive / $shellCompDirectiveKeepOrder) % 2)
        if test $keeporder -ne 0
            return 0
        end
        return 1
    end

    function __podman_prepare_completions
        set --erase __podman_comp_results
        __podman_perform_completion_once
        if test -z "$__podman_perform_completion_once_result"
            return 1
        end
        set -l directive (string sub --start 2 $__podman_perform_completion_once_result[-1])
        set --global __podman_comp_results $__podman_perform_completion_once_result[1..-2]
        set -l shellCompDirectiveError 1
        set -l shellCompDirectiveNoSpace 2
        set -l shellCompDirectiveNoFileComp 4
        set -l shellCompDirectiveFilterFileExt 8
        set -l shellCompDirectiveFilterDirs 16
        if test -z "$directive"
            set directive 0
        end
        set -l compErr (math (math --scale 0 $directive / $shellCompDirectiveError) % 2)
        if test $compErr -eq 1
            return 1
        end
        set -l filefilter (math (math --scale 0 $directive / $shellCompDirectiveFilterFileExt) % 2)
        set -l dirfilter (math (math --scale 0 $directive / $shellCompDirectiveFilterDirs) % 2)
        if test $filefilter -eq 1; or test $dirfilter -eq 1
            return 1
        end
        set -l nospace (math (math --scale 0 $directive / $shellCompDirectiveNoSpace) % 2)
        set -l nofiles (math (math --scale 0 $directive / $shellCompDirectiveNoFileComp) % 2)
        if test $nospace -ne 0; or test $nofiles -eq 0
            set -l prefix (commandline -t | string escape --style=regex)
            set -l completions (string match -r -- "^$prefix.*" $__podman_comp_results)
            set --global __podman_comp_results $completions
            set -l numComps (count $__podman_comp_results)
            if test $numComps -eq 1; and test $nospace -ne 0
                set -l split (string split --max 1 \t $__podman_comp_results[1])
                set -l lastChar (string sub -s -1 -- $split)
                if not string match -r -q "[@=/:.,]" -- "$lastChar"
                    set --global __podman_comp_results $split[1] $split[1].
                end
            end
            if test $numComps -eq 0; and test $nofiles -eq 0
                return 1
            end
        end
        return 0
    end

    if type -q "podman"
        complete --do-complete "podman " > /dev/null 2>&1
    end

    complete -c podman -e
    complete -c podman -n '__podman_clear_perform_completion_once_result'
    complete -c podman -n 'not __podman_requires_order_preservation && __podman_prepare_completions' -f -a '$__podman_comp_results'
    complete -k -c podman -n '__podman_requires_order_preservation && __podman_prepare_completions' -f -a '$__podman_comp_results'
  '';
}
