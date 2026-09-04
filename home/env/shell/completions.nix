{ lib, pkgs, ... }:

let
  # 通用/系统级命令的包内 fish vendor 补全（cmd → 包）。
  # 桌面/应用专属补全跟随各自消费者模块（de/hyprland、de/niri、de/noctalia、leisure/player）。
  fishVendorCompletions = {
    nix = pkgs.nix;
    nixos-rebuild = pkgs.nixos-rebuild;
    nh = pkgs.nh;
    codex = pkgs.codex;
    eza = pkgs.eza;
    flatpak = pkgs.flatpak;
    nixos-firewall-tool = pkgs.nixos-firewall-tool;
    podman-remote = pkgs.podman;
    rclone = pkgs.rclone;
    starship = pkgs.starship;
    tree-sitter = pkgs.tree-sitter;
    wl-copy = pkgs.wl-clipboard;
    wl-paste = pkgs.wl-clipboard;
    ya = pkgs.yazi;
    darkman = pkgs.darkman;
  };
in
{
  xdg.configFile = lib.mkMerge [
    (lib.mapAttrs'
      (cmd: pkg: lib.nameValuePair "fish/completions/${cmd}.fish" {
        source = "${pkg}/share/fish/vendor_completions.d/${cmd}.fish";
      })
      fishVendorCompletions)

    # Bash 补全中没有包内 Fish 版本的命令，统一由 conf.d 注册手写补全。
    {
      "fish/conf.d/bash-missing-completions.fish" = {
        text = ''
    function __fish_bash_missing_help_options
      set -l words (commandline --current-process --tokenize --cut-at-cursor)
      set -l cmd $words[1]
      test -n "$cmd"; or return
      if not command -sq $cmd
        printf '%s\n' --help --version
        return
      end

      set -l options (
        command $cmd --help 2>&1 |
        string match -r -a -- '(^|[[:space:]])-{1,2}[[:alnum:]][[:alnum:]_-]*' |
        string replace -r "^[[:space:]]" ""
      )
      if set -q options[1]
        printf '%s\n' $options
      else
        printf '%s\n' --help --version
      end
    end

    function __fish_bash_missing_lxc_names
      switch $argv[1]
        case running
          command lxc-ls --running -1 2>/dev/null
        case stopped
          command lxc-ls --stopped -1 2>/dev/null
        case defined
          command lxc-ls --defined -1 2>/dev/null
        case frozen
          command lxc-ls --frozen -1 2>/dev/null
      end
    end

    function __fish_bash_missing_lxc_complete
      set -l words (commandline --current-process --tokenize --cut-at-cursor)
      set -l cmd $words[1]
      __fish_bash_missing_help_options

      switch $cmd
        case lxc-attach lxc-cgroup lxc-checkpoint lxc-console lxc-device lxc-freeze lxc-stop
          __fish_bash_missing_lxc_names running
        case lxc-destroy lxc-execute lxc-snapshot lxc-start
          __fish_bash_missing_lxc_names stopped
        case lxc-copy lxc-info lxc-monitor lxc-wait
          __fish_bash_missing_lxc_names defined
        case lxc-unfreeze
          __fish_bash_missing_lxc_names frozen
      end
    end

    set -l __fish_bash_missing_lxc_commands \
      lxc-attach lxc-autostart lxc-cgroup lxc-checkpoint lxc-config lxc-console \
      lxc-copy lxc-create lxc-destroy lxc-device lxc-execute lxc-freeze \
      lxc-info lxc-ls lxc-monitor lxc-snapshot lxc-start lxc-stop lxc-top \
      lxc-unfreeze lxc-unshare lxc-usernsexec lxc-wait
    for cmd in $__fish_bash_missing_lxc_commands
      complete -c $cmd -a '(__fish_bash_missing_lxc_complete)'
    end
    function __fish_bash_missing_lxc_config_items
      command lxc-config -l 2>/dev/null
    end
    complete -c lxc-config -a '(__fish_bash_missing_lxc_config_items)'

    # 旧 nix-* 命令仍由 nix-bash-completions 提供 Bash 补全；Fish 侧至少保持
    # 同一批命令的 --help/--version 与当前 CLI 暴露的选项可见。
    set -l __fish_bash_missing_nix_commands \
      nix-build nix-channel nix-collect-garbage nix-copy-closure nix-env nix-hash \
      nix-install-package nix-instantiate nix-prefetch-url nix-push nix-shell \
      nix-store
    for cmd in $__fish_bash_missing_nix_commands
      complete -c $cmd -a '(__fish_bash_missing_help_options)'
    end

    complete -c nixos-container -n '__fish_use_subcommand' -a \
      'create destroy exec list list-generations login mount run show-ip start stop'
    complete -c nixos-container -a '(__fish_bash_missing_help_options)'

    complete -c copilot -n '__fish_use_subcommand' -a \
      'completion help init login mcp plugin plugins skill update version'
    complete -c copilot -l model -x
    complete -c copilot -l effort -x -a 'low medium high xhigh'
    complete -c copilot -l reasoning-effort -x -a 'low medium high xhigh'
    complete -c copilot -l prompt -r
    complete -c copilot -l resume -r
    complete -c copilot -l share
    complete -c copilot -l output-format -x -a 'text json'
    complete -c copilot -l mode -x -a 'interactive autopilot plan'

    complete -c npm -n '__fish_use_subcommand' -a \
      'access adduser audit bugs cache ci completion config dedupe deprecate diff \
      dist-tag docs doctor edit exec explain explore find-dupes fund get help \
      help-search init install install-ci-test install-test link ll login logout \
      ls org outdated owner pack ping pkg prefix profile prune publish query rebuild \
      repo restart root run sbom search set shrinkwrap star stars start stop team \
      test token undeprecate uninstall unpublish unstar update version view whoami'
    complete -c npm -s g -l global
    complete -c npm -s l -l help -l version
    complete -c npm -l json -l silent -l quiet -l verbose
    complete -c npm -l location -x -a 'global local project'
    complete -c npm -l prefix -r
    complete -c npm -l workspace -r
    complete -c npm -l workspaces -l include-workspace-root
    complete -c npm -l registry -r

    function __fish_bash_missing_sops_complete
      set -l words (commandline --current-process --tokenize --cut-at-cursor)
      set -l current (commandline --current-token --cut-at-cursor)
      if string match -q -- '-*' $current
        command sops $words[2..-1] $current --generate-bash-completion 2>/dev/null
      else
        command sops $words[2..-1] --generate-bash-completion 2>/dev/null
      end
    end
    complete -c sops -a '(__fish_bash_missing_sops_complete)'

    complete -c fdformat -s f -l from -x -a track_num
    complete -c fdformat -s t -l to -x -a track_num
    complete -c fdformat -s r -l repair -x -a track_num
    complete -c fdformat -l no-verify -l help -l version

    complete -c newgrp -s h -l help -l version
    complete -c newgrp -s c -l command -r -a '(__fish_complete_command)'
    complete -c newgrp -n 'not __fish_seen_argument -s c -l command' -a '(__fish_complete_groups)'

    complete -c pg -s c -s e -s f -s n -s r -s s -s h -s V
    complete -c pg -l help -l version
    complete -c pg -s p -x -a prompt
    complete -c pg -a '-number +number +/pattern/'

    function __fish_bash_missing_raw_devices
      command find /dev/raw -mindepth 1 -maxdepth 1 -print 2>/dev/null
    end
    complete -c raw -l query -l all -l help -l version
    complete -c raw -a '(__fish_bash_missing_raw_devices)'

    complete -c tunelp -s i -l irq -x -a number
    complete -c tunelp -s t -l time -x -a milliseconds
    complete -c tunelp -s c -l chars -x -a number
    complete -c tunelp -s w -l wait -x -a microseconds
    complete -c tunelp -s a -l abort -x -a 'off on'
    complete -c tunelp -s o -l check-status -x -a 'off on'
    complete -c tunelp -s C -l careful -x -a 'off on'
    complete -c tunelp -l status -l reset
    complete -c tunelp -s q -l print-irq -x -a 'off on'
    complete -c tunelp -l help -l version

    complete -c powerprofilesctl -s h -l help
    complete -c powerprofilesctl -n '__fish_use_subcommand' -a \
      'list list-holds list-actions get set configure-action configure-battery-aware \
      query-battery-aware launch version'
    complete -c powerprofilesctl -n '__fish_seen_subcommand_from set' -a \
      'performance balanced power-saver'

    function __fish_bash_missing_storagectl_json
      command storagectl --json=help 2>/dev/null
    end
    complete -c storagectl -s h -l help -l version -l no-pager -l no-legend -l no-ask-password
    complete -c storagectl -l system -l user
    complete -c storagectl -l json -x -a '(__fish_bash_missing_storagectl_json)'
    complete -c storagectl -n '__fish_use_subcommand' -a 'volumes templates providers help'

    complete -c systemd-confext -s h -l help -l version -l no-pager -l no-legend -l no-reload -l force
    complete -c systemd-confext -l root -r -a '(__fish_complete_directories)'
    complete -c systemd-confext -l json -x -a 'pretty short off'
    complete -c systemd-confext -l noexec -x -a 'no yes'
    complete -c systemd-confext -l image-policy -r
    complete -c systemd-confext -l mutable -x -a 'yes no auto import ephemeral ephemeral-import help'
    complete -c systemd-confext -n '__fish_use_subcommand' -a 'status merge unmerge refresh list'

    function __fish_bash_missing_resolve_values
      set -l option $argv[1]
      command systemd-resolve --legend=no $option help 2>/dev/null
      echo help
    end
    function __fish_bash_missing_systemd_interfaces
      command ls /sys/class/net 2>/dev/null | string match -v -- lo
    end
    complete -c systemd-resolve -s h -l help -l version -l no-pager -s 4 -s 6
    complete -c systemd-resolve -l service -l openpgp -l tlsa -l status -l statistics
    complete -c systemd-resolve -l reset-statistics -l flush-caches -l reset-server-features -l revert
    complete -c systemd-resolve -l service-address -x -a 'yes no'
    complete -c systemd-resolve -l service-txt -x -a 'yes no'
    complete -c systemd-resolve -l cname -x -a 'yes no'
    complete -c systemd-resolve -l search -x -a 'yes no'
    complete -c systemd-resolve -l legend -x -a 'yes no'
    complete -c systemd-resolve -s i -l interface -x -a '(__fish_bash_missing_systemd_interfaces)'
    complete -c systemd-resolve -s p -l protocol -x -a '(__fish_bash_missing_resolve_values -p)'
    complete -c systemd-resolve -s t -l type -x -a '(__fish_bash_missing_resolve_values -t)'
    complete -c systemd-resolve -s c -l class -x -a '(__fish_bash_missing_resolve_values -c)'
    complete -c systemd-resolve -l raw -x -a 'payload packet'
    complete -c systemd-resolve -l set-dns -l set-domain -l set-nta -r
    complete -c systemd-resolve -l set-llmnr -l set-mdns -x -a 'yes no resolve'
    complete -c systemd-resolve -l set-dnsovertls -x -a 'yes no opportunistic'
    complete -c systemd-resolve -l set-dnssec -x -a 'yes no allow-downgrade'

    complete -c systemd-sysinstall -s h -l help -l version
    complete -c systemd-sysinstall -l welcome -l chrome -l confirm -l summary -l reboot \
      -l mute-console -l copy-locale -l copy-keymap -l copy-timezone -x -a 'yes no'
    complete -c systemd-sysinstall -l erase -l variables -x -a 'yes no auto'
    complete -c systemd-sysinstall -l definitions -r -a '(__fish_complete_directories)'
    complete -c systemd-sysinstall -l kernel -r
    complete -c systemd-sysinstall -l set-credential -r
    complete -c systemd-sysinstall -l load-credential -r

    function __fish_bash_missing_swap_names
      command swapon --show=NAME --raw --noheading 2>/dev/null
    end
    function __fish_bash_missing_swap_uuids
      command swapon --show=UUID --noheading 2>/dev/null
    end
    function __fish_bash_missing_swap_labels
      command swapon --show=LABEL --noheading 2>/dev/null
    end
    complete -c swapoff -s L -x -a '(__fish_bash_missing_swap_labels)'
    complete -c swapoff -s U -x -a '(__fish_bash_missing_swap_uuids)'
    complete -c swapoff -s a -l all -s v -l verbose -l help -l version
    complete -c swapoff -a '(__fish_bash_missing_swap_names)'

    function __fish_bash_missing_libvirt_complete
      set -l words (commandline --current-process --tokenize --cut-at-cursor)
      set -l cmd $words[1]
      command $cmd -q complete -- $words[2..-1] 2>/dev/null
    end
    for cmd in virsh virt-admin
      complete -c $cmd -s c -l connect -r
      complete -c $cmd -s r -l readonly
      complete -c $cmd -s q -l quiet
      complete -c $cmd -s h -l help -s V -l version
      complete -c $cmd -a '(__fish_bash_missing_libvirt_complete)'
    end
  '';
      };
    }


    {
      "fish/completions/podman.fish" = {
        source = pkgs.runCommand "podman-fish-completion" { } ''
    export HOME="$TMPDIR"
    ${pkgs.podman}/bin/podman completion fish > "$out"
  '';
      };
    }


    {
      "fish/completions/howdy.fish" = {
        text = ''
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
      };
    }
  ];

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
