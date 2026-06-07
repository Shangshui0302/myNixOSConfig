{ pkgs, lib, ... }:

let
  # Yazi theme — myargonaut
  myargonaut = pkgs.writeTextFile {
    name = "myargonaut.yazi";
    destination = "/flavor.toml";
    text = ''
      [mgr]
      cwd = { fg = "#fffaf4", bold = true }
      hovered         = { bg = "#1a1a2e" }
      preview_hovered = { underline = true }
      find_keyword  = { fg = "#ffd242", reversed = true }
      find_position = { fg = "#888888", bold = true }
      marker_copied   = { fg = "#abe15b", bg = "#abe15b" }
      marker_cut      = { fg = "#ff2740", bg = "#ff2740" }
      marker_marked   = { fg = "#8ce10b", bg = "#8ce10b" }
      marker_selected = { fg = "#00d8eb", bg = "#00d8eb" }
      count_copied   = { fg = "#0e1019", bg = "#abe15b", bold = true }
      count_cut      = { fg = "#0e1019", bg = "#ff2740", bold = true }
      count_selected = { fg = "#0e1019", bg = "#00d8eb", bold = true }
      border_style = { fg = "#abe15b" }

      [status]
      overall  = { fg = "#abe15b", bold = true }
      sep_left  = { open = "", close = "" }
      sep_right = { open = "", close = "" }
      progress_label  = { bold = true }
      progress_normal = { fg = "#abe15b", bg = "#1a1a2e" }
      progress_error  = { fg = "#ff2740", bg = "#1a1a2e" }
      perm_type  = { fg = "#abe15b" }
      perm_read  = { fg = "#8ce10b" }
      perm_write = { fg = "#ffd242" }
      perm_exec  = { fg = "#ff2740" }
      perm_sep   = { fg = "#888888" }

      [mode]
      normal_main = { bg = "#abe15b", fg = "#0e1019", bold = true }
      normal_alt  = { bg = "#1a1a2e", fg = "#abe15b" }
      select_main = { bg = "#00d8eb", fg = "#0e1019", bold = true }
      select_alt  = { bg = "#1a1a2e", fg = "#00d8eb" }
      unset_main = { bg = "#888888", fg = "#0e1019", bold = true }
      unset_alt  = { bg = "#1a1a2e", fg = "#888888" }

      [input]
      border   = { fg = "#abe15b" }
      value    = { fg = "#fffaf4" }
      selected = { reversed = true }

      [tabs]
      active   = { fg = "#0e1019", bg = "#abe15b", bold = true }
      inactive = { fg = "#888888", bg = "#1a1a2e" }

      [cmp]
      border = { fg = "#abe15b", bg = "#0e1019" }

      [tasks]
      border  = { fg = "#abe15b" }
      hovered = { fg = "#8ce10b", underline = true }

      [which]
      cols = 3
      mask = { bg = "#0e1019" }
      cand = { fg = "#8ce10b" }
      rest = { fg = "#888888" }
      desc = { fg = "#fffaf4", bold = true }
      separator  = "  "
      separator_style = { fg = "#abe15b" }

      [help]
      name   = { fg = "#abe15b", bold = true }
      on     = { fg = "#8ce10b" }
      run    = { fg = "#00d8eb" }
      desc   = { fg = "#fffaf4" }
      hover  = { reversed = true }
      footer = { fg = "#abe15b", bold = true }

      [spot]
      border = { fg = "#abe15b" }
      cell   = { fg = "#fffaf4" }

      [filetype]
      rules = [
        { mime = "image/*", fg = "#94e2d5" }
        { mime = "video/*", fg = "#f9e2af" }
        { mime = "audio/*", fg = "#f9e2af" }
        { mime = "application/zip", fg = "#f5c2e7" }
        { mime = "application/gzip", fg = "#f5c2e7" }
        { mime = "application/x-tar", fg = "#f5c2e7" }
        { mime = "application/x-7z*", fg = "#f5c2e7" }
        { mime = "application/x-rar*", fg = "#f5c2e7" }
        { mime = "application/pdf", fg = "#a6e3a1" }
        { mime = "text/markdown", fg = "#abe15b" }
        { mime = "text/html", fg = "#ff2740" }
        { url = "*.nix", fg = "#8ce10b" }
        { url = "*.rs", fg = "#ff2740" }
        { url = "*.py", fg = "#ffd242" }
        { url = "*.js", fg = "#ffd242" }
        { url = "*.ts", fg = "#00d8eb" }
        { url = "*.lua", fg = "#00d8eb" }
        { url = "*.toml", fg = "#888888" }
        { url = "*.json", fg = "#ffd242" }
        { url = "*.yaml", fg = "#ff2740" }
        { url = "*.yml", fg = "#ff2740" }
        { url = "flake.lock", fg = "#888888" }
        { url = "flake.nix", fg = "#8ce10b" }
        { url = "*.conf", fg = "#888888" }
        { url = "Makefile", fg = "#abe15b" }
        { url = "*.sh", fg = "#abe15b" }
        { mime = "inode/x-empty", fg = "#888888" }
        { url = "*", is = "orphan", fg = "#ff2740" }
      ]

      [icon]
      prepend_dirs = [
        { name = "Desktop", text = "", fg = "#8ce10b" }
        { name = "Documents", text = "󱔗", fg = "#8ce10b" }
        { name = "Downloads", text = "", fg = "#8ce10b" }
        { name = "Pictures", text = "", fg = "#8ce10b" }
        { name = "Videos", text = "󰑈", fg = "#8ce10b" }
        { name = "Music", text = "󰝚", fg = "#8ce10b" }
        { name = "home", text = "", fg = "#8ce10b" }
        { name = "Projects", text = "", fg = "#8ce10b" }
        { name = "myNixOSConfig", text = "󱄅", fg = "#8ce10b" }
        { name = ".git", text = "", fg = "#abe15b" }
        { name = ".config", text = "", fg = "#8ce10b" }
        { name = ".cache", text = "", fg = "#888888" }
        { name = ".local", text = "", fg = "#888888" }
        { name = "node_modules", text = "", fg = "#888888" }
      ]
      prepend_exts = [
        { name = "nix", text = "󰋗", fg = "#8ce10b" }
        { name = "lock", text = "󰋗", fg = "#888888" }
        { name = "rs", text = "", fg = "#ff2740" }
        { name = "py", text = "", fg = "#ffd242" }
        { name = "js", text = "", fg = "#ffd242" }
        { name = "ts", text = "", fg = "#00d8eb" }
        { name = "lua", text = "", fg = "#00d8eb" }
        { name = "json", text = "", fg = "#ffd242" }
        { name = "yaml", text = "", fg = "#ff2740" }
        { name = "yml", text = "", fg = "#ff2740" }
        { name = "toml", text = "", fg = "#888888" }
        { name = "md", text = "󰉿", fg = "#abe15b" }
        { name = "txt", text = "󰉿", fg = "#888888" }
        { name = "sh", text = "", fg = "#abe15b" }
        { name = "bash", text = "", fg = "#abe15b" }
        { name = "fish", text = "", fg = "#abe15b" }
        { name = "conf", text = "", fg = "#888888" }
        { name = "css", text = "", fg = "#00d8eb" }
        { name = "html", text = "", fg = "#ff2740" }
        { name = "svg", text = "󰜘", fg = "#ffd242" }
        { name = "png", text = "󰉏", fg = "#94e2d5" }
        { name = "jpg", text = "󰉏", fg = "#94e2d5" }
        { name = "jpeg", text = "󰉏", fg = "#94e2d5" }
        { name = "gif", text = "󰉏", fg = "#94e2d5" }
        { name = "mp4", text = "", fg = "#f9e2af" }
        { name = "mkv", text = "", fg = "#f9e2af" }
        { name = "mp3", text = "", fg = "#f9e2af" }
        { name = "flac", text = "", fg = "#f9e2af" }
        { name = "wav", text = "", fg = "#f9e2af" }
        { name = "zip", text = "󰛫", fg = "#f5c2e7" }
        { name = "tar.gz", text = "󰛫", fg = "#f5c2e7" }
        { name = "tar.xz", text = "󰛫", fg = "#f5c2e7" }
        { name = "rar", text = "󰛫", fg = "#f5c2e7" }
        { name = "7z", text = "󰛫", fg = "#f5c2e7" }
        { name = "pdf", text = "", fg = "#a6e3a1" }
        { name = "desktop", text = "", fg = "#8ce10b" }
      ]
      prepend_conds = [
        { if = "dir & hovered", text = "", fg = "#abe15b" }
        { if = "dir", text = "", fg = "#8ce10b" }
        { if = "exec", text = "", fg = "#abe15b" }
        { if = "!dir & !exec", text = "", fg = "#888888" }
      ]
    '';
  };

  # Yazi community themes
  yazi-flavors = pkgs.fetchFromGitHub {
    owner = "yazi-rs"; repo = "flavors";
    rev = "0f9204bc948c8313963f5c9d571a82edc201f8aa";
    hash = "sha256-qWNArjWuxWL+rOjLzyIniW5hJgWiAWTCgXmMXJpaWZE=";
  };
  catppuccin-mocha = pkgs.runCommand "catppuccin-mocha.yazi" { } ''
    cp -r ${yazi-flavors}/catppuccin-mocha.yazi $out
  '';
  tokyo-night = pkgs.fetchFromGitHub {
    owner = "BennyOe"; repo = "tokyo-night.yazi";
    rev = "8e6296f14daff24151c736ebd0b9b6cd89b02b03";
    hash = "sha256-LArhRteD7OQRBguV1n13gb5jkl90sOxShkDzgEf3PA0=";
  };
  nord = pkgs.fetchFromGitHub {
    owner = "AdithyanA2005"; repo = "nord.yazi";
    rev = "1b1bf78deb30391095523acb94a6d9784744f92c";
    hash = "sha256-CcQBpR9fqUCXEZVznSQ1Yo8JPVE+fhhgM9QApTXaWPU=";
  };
  synthwave84 = pkgs.fetchFromGitHub {
    owner = "CFY98"; repo = "synthwave84.yazi";
    rev = "b7bb92e406f6575979ed8fa8e602601620017d5f";
    hash = "sha256-NmBjjiae91BY0x3OxtLWiI2wqh3x+V/PwrvWqRp4QPI=";
  };
  lain = pkgs.fetchFromGitHub {
    owner = "identityapproved"; repo = "lain.yazi";
    rev = "e2a3bb28412c92febd0152b762d3e0cf049ef139";
    hash = "sha256-oxLgkIUzTJwCypqGf7mSlmNyxflYuuzox6oocrQaCb8=";
  };
  kanagawa-paper = pkgs.fetchFromGitHub {
    owner = "melindachang"; repo = "kanagawa-paper.yazi";
    rev = "7f3cd1d8a579cc8a38fca67fcb3cb018e4d7171c";
    hash = "sha256-QSDcHvQwUABGM76OYW2rrFcSkpo/q7e0bBZLbpCIiqw=";
  };
in
{
  home.packages = with pkgs; [ yazi fastfetch ];

  # ---- btop ----
  xdg.configFile."btop/btop.conf".text = ''
    color_theme = "blackgolden"
    theme_background = false
    truecolor = true
    force_tty = false
    presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty"
    vim_keys = false
    rounded_corners = true
    terminal_sync = true
    graph_symbol = "braille"
    shown_boxes = "cpu mem net proc"
    update_ms = 2000
    proc_sorting = "cpu lazy"
    proc_reversed = false
    proc_tree = false
    proc_colors = true
    proc_gradient = true
    proc_mem_bytes = true
    proc_cpu_graphs = true
    cpu_invert_lower = true
    cpu_single_graph = false
    show_uptime = true
    check_temp = true
    cpu_sensor = "Auto"
    show_coretemp = true
    temp_scale = "celsius"
    base_10_sizes = false
    show_cpu_freq = true
    clock_format = "%X"
    background_update = true
    mem_graphs = true
    show_swap = true
    swap_disk = true
    show_disks = true
    only_physical = true
    use_fstab = true
    show_io_stat = true
    io_mode = false
    net_download = 100
    net_upload = 100
    net_auto = true
    net_sync = true
    show_battery = true
    selected_battery = "Auto"
    show_battery_watts = true
    log_level = "WARNING"
    nvml_measure_pcie_speeds = true
    rsmi_measure_pcie_speeds = true
    gpu_mirror_graph = true
    shown_gpus = "nvidia amd intel"
  '';

  xdg.configFile."btop/themes/blackgolden.theme".text = ''
    theme[main_bg]="#0e1019"
    theme[main_fg]="#e0e2ef"
    theme[title]="#ffec15"
    theme[hi_fg]="#c57358"
    theme[selected_bg]="#302c2a"
    theme[selected_fg]="#e0e2ef"
    theme[inactive_fg]="#b3b7c2"
    theme[proc_misc]="#006ff1"
    theme[cpu_box]="#595676"
    theme[mem_box]="#595676"
    theme[net_box]="#595676"
    theme[proc_box]="#595676"
    theme[div_line]="#38364a"
    theme[temp_start]="#ffec15"
    theme[temp_mid]="#006ff1"
    theme[temp_end]="#c57358"
    theme[cpu_start]="#ffec15"
    theme[cpu_mid]="#006ff1"
    theme[cpu_end]="#c57358"
    theme[free_start]="#ffec15"
    theme[free_mid]="#006ff1"
    theme[free_end]="#c57358"
    theme[cached_start]="#ffec15"
    theme[cached_mid]="#006ff1"
    theme[cached_end]="#c57358"
    theme[available_start]="#ffec15"
    theme[available_mid]="#006ff1"
    theme[available_end]="#c57358"
    theme[used_start]="#ffec15"
    theme[used_mid]="#006ff1"
    theme[used_end]="#c57358"
    theme[download_start]="#ffec15"
    theme[download_mid]="#006ff1"
    theme[download_end]="#c57358"
    theme[upload_start]="#ffec15"
    theme[upload_mid]="#006ff1"
    theme[upload_end]="#c57358"
  '';

  # ---- yazi ----
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";

    initLua = ''require("starship"):setup()'';

    plugins = {
      git = pkgs.yaziPlugins.git;
      full-border = pkgs.yaziPlugins.full-border;
      smart-enter = pkgs.yaziPlugins.smart-enter;
      jump-to-char = pkgs.yaziPlugins.jump-to-char;
      wl-clipboard = pkgs.yaziPlugins.wl-clipboard;
      mime-ext = pkgs.yaziPlugins.mime-ext;
      yatline = pkgs.yaziPlugins.yatline;
      yatline-githead = pkgs.yaziPlugins.yatline-githead;
      starship = pkgs.yaziPlugins.starship;
    };

    flavors = {
      inherit myargonaut catppuccin-mocha tokyo-night nord synthwave84 lain kanagawa-paper;
    };

    theme.flavor.dark = "myargonaut";

    settings = {
      manager = {
        show_hidden = true;
        sort_by = "alphabetical";
        sort_dir_first = true;
        sort_sensitive = false;
        linemode = "none";
        show_symlink = true;
        tab_width = 1;
        ratio = [ 2 3 4 ];
      };
      preview = { tab_size = 4; max_width = 1000; max_height = 1000; };
      opener = {
        edit = [{ run = "${pkgs.neovim}/bin/nvim \$@"; block = true; for = "unix"; }];
        play = [{ run = "${pkgs.mpv}/bin/mpv \$@"; block = false; for = "unix"; }];
      };
      open.prepend_rules = [
        { url = "*.md"; use = "edit"; }
        { url = "*.nix"; use = "edit"; }
        { url = "*.txt"; use = "edit"; }
        { url = "*.rs"; use = "edit"; }
        { url = "*.py"; use = "edit"; }
        { url = "*.js"; use = "edit"; }
        { url = "*.ts"; use = "edit"; }
        { url = "*.json"; use = "edit"; }
        { url = "*.toml"; use = "edit"; }
        { url = "*.yaml"; use = "edit"; }
        { url = "*.lua"; use = "edit"; }
      ];
      plugin.preloaders = [
        { mime = "image/*"; run = "magick"; }
        { mime = "video/*"; run = "ffmpeg"; }
      ];
    };

    keymap = {
      manager.prepend_keymap = [
        { on = "f"; run = "plugin jump-to-char"; desc = "Jump to char"; }
        { on = "l"; run = "plugin smart-enter"; desc = "Enter child / open file"; }
        { on = "<Enter>"; run = "plugin smart-enter"; desc = "Enter child / open file"; }
      ];
      tasks.prepend_keymap = [
        { on = "l"; run = "plugin smart-enter"; desc = "Enter child / open file"; }
        { on = "<Enter>"; run = "plugin smart-enter"; desc = "Enter child / open file"; }
      ];
    };
  };
}
