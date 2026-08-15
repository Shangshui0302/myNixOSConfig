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


  programs.bash = {
    enable = true;
    initExtra = ''
      # kmscon raw VT 模式下 pam_systemd 可能没注入 session 变量，兜底
      if [ -z "$XDG_RUNTIME_DIR" ] && [ -d "/run/user/$(id -u)" ]; then
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"
        export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
      fi

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
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish; }
    ];

    interactiveShellInit = ''
      # 针对 Distrobox 容器的特殊处理：优先使用容器内部安装的软件
      if set -q DISTROBOX_ENTERED
        set -x PATH /usr/local/bin /usr/bin /bin $PATH
      end

      # distrobox-export 导出的 CLI 工具（宿主机直接调用容器内命令）
      fish_add_path $HOME/.local/bin

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
  xdg.configFile."fish/completions/noctalia.fish".text = ''
    complete -c noctalia -f

    # Options
    complete -c noctalia -s h -l help -d "Show help message"
    complete -c noctalia -s v -l version -d "Show version information"
    complete -c noctalia -s d -l daemon -d "Run in background"

    # Main subcommands
    complete -c noctalia -n "not __fish_seen_subcommand_from msg theme config plugins" -a msg -d "Send a command to the running instance"
    complete -c noctalia -n "not __fish_seen_subcommand_from msg theme config plugins" -a theme -d "Generate a color palette from an image"
    complete -c noctalia -n "not __fish_seen_subcommand_from msg theme config plugins" -a config -d "Validate config and support/replay helpers"
    complete -c noctalia -n "not __fish_seen_subcommand_from msg theme config plugins" -a plugins -d "Offline plugin author tools (lint)"

    # config subcommands
    complete -c noctalia -n "__fish_seen_subcommand_from config" -a "validate" -d "Check config validity"
    complete -c noctalia -n "__fish_seen_subcommand_from config" -a "export" -d "Print the active config as TOML"
    complete -c noctalia -n "__fish_seen_subcommand_from config" -a "settings-count" -d "Count Settings UI controls"
    complete -c noctalia -n "__fish_seen_subcommand_from config" -a "replay-report" -d "Reconstruct config from a support report"

    # plugins subcommands
    complete -c noctalia -n "__fish_seen_subcommand_from plugins" -a "lint" -d "Cross-check plugin settings"

    # msg subcommands
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "bar-auto-hide-set" -d "Set auto-hide state for a bar"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "bar-hide" -d "Hide one or all bars and release their layout gaps"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "bar-layer-set" -d "Set one or all bar layers"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "bar-show" -d "Show one or all bars"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "bar-toggle" -d "Toggle visibility for one or all bars"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "bluetooth-disable" -d "Disable Bluetooth"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "bluetooth-enable" -d "Enable Bluetooth"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "bluetooth-status" -d "Print Bluetooth state"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "bluetooth-toggle" -d "Toggle Bluetooth"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "brightness-down" -d "Decrease brightness (defaults to current monitor)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "brightness-osd" -d "Show brightness OSD without changing brightness"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "brightness-set" -d "Set brightness (defaults to current monitor)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "brightness-up" -d "Increase brightness (defaults to current monitor)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "caffeine-disable" -d "Disable caffeine (idle inhibitor)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "caffeine-enable" -d "Enable caffeine (idle inhibitor)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "caffeine-toggle" -d "Toggle caffeine (idle inhibitor)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "clipboard-clear" -d "Clear clipboard history"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "color-scheme-get" -d "Print active color scheme: <source> <name> (source is builtin, wallpaper, community, or custom)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "color-scheme-set" -d "Set palette source and selection in settings.toml (builtin name, wallpaper generator scheme, community id, or custom scheme folder name)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "config-reload" -d "Reload the config file"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "desktop-widgets-edit" -d "Open the desktop widgets editor"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "desktop-widgets-exit" -d "Close the desktop widgets editor"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "desktop-widgets-hide" -d "Hide desktop widgets now (runtime only; does not change the saved setting)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "desktop-widgets-show" -d "Show desktop widgets now (runtime only; does not change the saved setting)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "desktop-widgets-toggle" -d "Toggle desktop widgets visibility (runtime only; does not change the saved setting)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "desktop-widgets-toggle-edit" -d "Toggle desktop widgets edit mode"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "dock-hide" -d "Hide the dock (persists override)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "dock-reload" -d "Reload dock configuration"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "dock-show" -d "Show the dock (persists override)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "dock-toggle" -d "Toggle dock visibility (persists override)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "dpms-off" -d "Turn monitors off"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "dpms-on" -d "Turn monitors on"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "effects-profile-set" -d "Set the EasyEffects output or input profile"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "greeter-sync" -d "Sync wallpaper, colors, and monitor layout to Noctalia Greeter"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "lockscreen-widgets-edit" -d "Open the lockscreen widgets editor"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "lockscreen-widgets-exit" -d "Close the lockscreen widgets editor"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "lockscreen-widgets-toggle-edit" -d "Toggle lockscreen widgets edit mode"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "media" -d "Control active media playback"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "mic-mute" -d "Toggle microphone mute"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "mic-volume-down" -d "Decrease microphone volume"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "mic-volume-set" -d "Set microphone volume"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "mic-volume-up" -d "Increase microphone volume"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "nightlight-disable" -d "Disable night light schedule"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "nightlight-enable" -d "Enable night light schedule"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "nightlight-force-toggle" -d "Toggle forced night light mode"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "nightlight-toggle" -d "Toggle night light schedule"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "notification-clear-active" -d "Dismiss all currently active notifications"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "notification-clear-history" -d "Clear notification history"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "notification-dnd-set" -d "Set notification Do Not Disturb state"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "notification-dnd-status" -d "Print notification Do Not Disturb state"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "notification-dnd-toggle" -d "Toggle notification Do Not Disturb state"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "notification-invoke-latest" -d "Invoke the default action of the most recent active notification"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "panel-close" -d "Close the active panel, or close the named panel if it is active"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "panel-open" -d "Open a panel by id, optionally with context (e.g. launcher /emo, control-center audio)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "panel-toggle" -d "Toggle a panel by id, optionally with context (e.g. launcher /emo, control-center audio)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "plugin" -d "Dispatch an event to a plugin entry"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "plugins" -d "Manage plugins and sources (list/enable/disable/update, source list/add/remove)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "power-cycle" -d "Switch to the next power profile in UPower's ordered list (wraps)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "power-set" -d "Set the UPower power profile (e.g. performance, balanced, power-saver)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "screenshot-fullscreen" -d "Capture the focused monitor by default, pick interactively with pick, or all outputs with all"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "screenshot-region" -d "Start an interactive region screenshot"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "session" -d "Run a built-in session action"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "settings-close" -d "Close the settings window"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "settings-open" -d "Open the settings window, or focus it if already open, optionally at a specific section"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "settings-toggle" -d "Toggle the settings window, optionally at a specific section"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "status" -d "Print current state as JSON"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "templates-apply" -d "Apply configured theme templates for the current palette"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "theme-mode-get" -d "Print the current resolved theme mode"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "theme-mode-set" -d "Set theme mode and persist to settings.toml"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "theme-mode-toggle" -d "Toggle theme mode between dark and light"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "volume-down" -d "Decrease speaker volume"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "volume-mute" -d "Toggle speaker mute"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "volume-set" -d "Set speaker volume"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "volume-up" -d "Increase speaker volume"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "wallpaper-get" -d "Print default wallpaper path, or effective path for an output"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "wallpaper-random" -d "Switch to a random wallpaper immediately"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "wallpaper-set" -d "Set wallpaper for all or a specific output (persisted)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "wifi-disable" -d "Disable Wi-Fi"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "wifi-enable" -d "Enable Wi-Fi"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "wifi-status" -d "Print Wi-Fi state"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "wifi-toggle" -d "Toggle Wi-Fi"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "window-switcher" -d "Open or close the window switcher overlay"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "workspace-alert-add" -d "Add a workspace alert (by number, name, or id)"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "workspace-alert-add-window" -d "Add a workspace alert for a window"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "workspace-alert-clear" -d "Clear a workspace alert"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "workspace-alert-clear-all" -d "Clear all workspace alerts"
    complete -c noctalia -n "__fish_seen_subcommand_from msg" -a "workspace-alert-status" -d "Print workspace alerts"
  '';
  xdg.dataFile."bash-completion/completions/noctalia".text = ''
    _noctalia_completion() {
        local cur prev words cword
        _init_completion -s || {
            COMPREPLY=()
            local cur="''${COMP_WORDS[COMP_CWORD]}"
        }

        local main_cmds="msg theme config plugins"
        local config_cmds="validate export settings-count replay-report"
        local plugins_cmds="lint"
        local msg_cmds="bar-auto-hide-set bar-hide bar-layer-set bar-show bar-toggle bluetooth-disable bluetooth-enable bluetooth-status bluetooth-toggle brightness-down brightness-osd brightness-set brightness-up caffeine-disable caffeine-enable caffeine-toggle clipboard-clear color-scheme-get color-scheme-set config-reload desktop-widgets-edit desktop-widgets-exit desktop-widgets-hide desktop-widgets-show desktop-widgets-toggle desktop-widgets-toggle-edit dock-hide dock-reload dock-show dock-toggle dpms-off dpms-on effects-profile-set greeter-sync lockscreen-widgets-edit lockscreen-widgets-exit lockscreen-widgets-toggle-edit media mic-mute mic-volume-down mic-volume-set mic-volume-up nightlight-disable nightlight-enable nightlight-force-toggle nightlight-toggle notification-clear-active notification-clear-history notification-dnd-set notification-dnd-status notification-dnd-toggle notification-invoke-latest panel-close panel-open panel-toggle plugin plugins power-cycle power-set screenshot-fullscreen screenshot-region session settings-close settings-open settings-toggle status templates-apply theme-mode-get theme-mode-set theme-mode-toggle volume-down volume-mute volume-set volume-up wallpaper-get wallpaper-random wallpaper-set wifi-disable wifi-enable wifi-status wifi-toggle window-switcher workspace-alert-add workspace-alert-add-window workspace-alert-clear workspace-alert-clear-all workspace-alert-status"

        if [[ ''${COMP_CWORD} -eq 1 ]]; then
            COMPREPLY=( $(compgen -W "$main_cmds --help --version --daemon" -- "$cur") )
        elif [[ ''${COMP_CWORD} -eq 2 ]]; then
            case "''${COMP_WORDS[1]}" in
                msg)
                    COMPREPLY=( $(compgen -W "$msg_cmds" -- "$cur") )
                    ;;
                config)
                    COMPREPLY=( $(compgen -W "$config_cmds" -- "$cur") )
                    ;;
                plugins)
                    COMPREPLY=( $(compgen -W "$plugins_cmds" -- "$cur") )
                    ;;
            esac
        fi
    }
    complete -F _noctalia_completion noctalia
  '';

  xdg.configFile."fish/completions/howdy.fish".text = ''
    complete -c howdy -f

    # Options
    complete -c howdy -s h -l help -d "Show help message and exit"
    complete -c howdy -s y -d "Skip all questions"
    complete -c howdy -l plain -d "Print machine-friendly output"
    complete -c howdy -s U -l user -x -d "Set the user account to use"

    # Commands
    set -l cmds add clear config disable list remove snapshot set test version
    complete -c howdy -n "not __fish_seen_subcommand_from $cmds" -a add -d "Add a new face model"
    complete -c howdy -n "not __fish_seen_subcommand_from $cmds" -a clear -d "Clear all face models"
    complete -c howdy -n "not __fish_seen_subcommand_from $cmds" -a config -d "Open config file"
    complete -c howdy -n "not __fish_seen_subcommand_from $cmds" -a disable -d "Disable or enable howdy"
    complete -c howdy -n "not __fish_seen_subcommand_from $cmds" -a list -d "List all face models"
    complete -c howdy -n "not __fish_seen_subcommand_from $cmds" -a remove -d "Remove a specific face model"
    complete -c howdy -n "not __fish_seen_subcommand_from $cmds" -a snapshot -d "Generate a snapshot from the camera"
    complete -c howdy -n "not __fish_seen_subcommand_from $cmds" -a set -d "Set a config option"
    complete -c howdy -n "not __fish_seen_subcommand_from $cmds" -a test -d "Test face recognition"
    complete -c howdy -n "not __fish_seen_subcommand_from $cmds" -a version -d "Print version"
  '';

  xdg.dataFile."bash-completion/completions/howdy".text = ''
    _howdy_completion() {
        local cur prev words cword
        _init_completion -s || {
            COMPREPLY=()
            local cur="''${COMP_WORDS[COMP_CWORD]}"
        }

        local cmds="add clear config disable list remove snapshot set test version"
        local opts="-h --help -y --plain -U --user"

        if [[ ''${COMP_CWORD} -eq 1 ]]; then
            COMPREPLY=( $(compgen -W "$cmds $opts" -- "$cur") )
        fi
    }
    complete -F _howdy_completion howdy
  '';

}
