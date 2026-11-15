{ pkgs, ... }:

let
  # Both shells read the same versioned DSH store without copying secrets into Nix.
  dshApiKey =
    pkgs.writers.writePython3 "dsh-api-key"
      {
        libraries = [ pkgs.python3Packages.ruamel-yaml ];
      }
      ''
        import os
        from pathlib import Path
        import sys
        import warnings

        from ruamel.yaml import YAML
        from ruamel.yaml.error import YAMLError

        home = Path(os.environ.get("DSH_HOME") or Path.home() / ".dsh")
        try:
            stream = (home / ".credentials.yaml").open(encoding="utf-8")
        except FileNotFoundError:
            sys.exit(0)
        except OSError:
            sys.exit("DSH: cannot open credentials file; API key not exported.")

        try:
            with stream:
                if os.fstat(stream.fileno()).st_mode & 0o077:
                    raise ValueError("credentials permissions are not owner-only")
                with warnings.catch_warnings():
                    warnings.simplefilter("error")
                    data = YAML(typ="safe").load(stream)
            if data is None or data == {}:
                sys.exit(0)
            if not isinstance(data, dict) or type(data.get("version")) is not int:
                raise ValueError("invalid credentials document")
            if data["version"] != 1:
                raise ValueError("unsupported credentials version")
            refs = data.get("refs")
            if refs is None:
                sys.exit(0)
            if not isinstance(refs, dict):
                raise ValueError("invalid credential references")
            if "DEEPSEEK_API_KEY" not in refs:
                sys.exit(0)
            key = refs["DEEPSEEK_API_KEY"]
            if not isinstance(key, str) or not key or any(c in key for c in "\0\r\n"):
                raise ValueError("invalid API key")
        except (OSError, UnicodeError, YAMLError, ValueError, Warning):
            # Parser messages may contain the secret-bearing source line.
            sys.exit("DSH: cannot read credentials; check YAML and mode 600.")
        print(key, end="")
      '';
in
{
  programs.eza = {
    enable = true;
    icons = "auto";
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    presets = [ "nerd-font-symbols" ];
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
        python_binary = [
          "python3"
          "python"
        ];
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
          {
            threshold = 20;
            style = "#ff2740 bold";
          }
          {
            threshold = 50;
            style = "#ffd242 bold";
          }
          {
            threshold = 100;
            style = "#abe15b bold";
          }
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
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      # kmscon raw VT 模式下 pam_systemd 可能没注入 session 变量，兜底
      if [ -z "$XDG_RUNTIME_DIR" ] && [ -d "/run/user/$(id -u)" ]; then
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"
        export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
      fi

      # headless profile 使用启动环境；保留用户已设置的值（包括空值）。
      if [ -z "''${DEEPSEEK_API_KEY+x}" ]; then
        if _dsh_key=$(${dshApiKey}) && [ -n "$_dsh_key" ]; then
          export DEEPSEEK_API_KEY="$_dsh_key"
        fi
        unset _dsh_key
      fi

      # ble.sh — 语法高亮、自动补全、Fish 风格建议
      source ${pkgs.blesh}/share/blesh/ble.sh
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
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair;
      }
      {
        name = "done";
        src = pkgs.fishPlugins.done;
      }
      {
        name = "grc";
        src = pkgs.fishPlugins.grc;
      }
      {
        name = "colored-man-pages";
        src = pkgs.fishPlugins.colored-man-pages;
      }
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish;
      }
    ];

    interactiveShellInit = ''
      # 针对 Distrobox 容器的特殊处理：优先使用容器内部安装的软件
      if set -q DISTROBOX_ENTERED
        # ~/.local/bin 中的 HM 管理包装器（如 nvim）优先于容器发行版包。
        set -x PATH $HOME/.local/bin /usr/local/bin /usr/bin /bin $PATH
      end

      # fish 问候
      set -g fish_greeting

      # 与 Bash 共用凭据解析，保留已有环境变量。
      if not set -q DEEPSEEK_API_KEY
        set -l _dsh_key (${dshApiKey})
        if test $status -eq 0; and test -n "$_dsh_key"
          set -gx DEEPSEEK_API_KEY $_dsh_key
        end
      end
    '';
  };
}
