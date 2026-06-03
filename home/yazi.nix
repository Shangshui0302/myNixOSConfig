{ pkgs, lib, ... }:

let
  # ============================================================================
  # myargonaut — Nix-generated Argonaut theme for Yazi
  # Matches the foot terminal Argonaut palette: cool-toned, blue-accented
  # ============================================================================
  myargonaut = pkgs.writeTextFile {
    name = "myargonaut.yazi";
    destination = "/flavor.toml";
    text = ''
      # myargonaut — Argonaut palette for Yazi
      # Generated via Nix for reproducibility

      # : Manager [[[
      [mgr]
      cwd = { fg = "#fffaf4", bold = true }

      hovered         = { bg = "#1a1a2e" }
      preview_hovered = { underline = true }

      find_keyword  = { fg = "#ffd242", reversed = true }
      find_position = { fg = "#888888", bold = true }

      marker_copied   = { fg = "#abe15b", bg = "#abe15b" }
      marker_cut      = { fg = "#ff2740", bg = "#ff2740" }
      marker_marked   = { fg = "#0092ff", bg = "#0092ff" }
      marker_selected = { fg = "#67fff0", bg = "#67fff0" }

      count_copied   = { fg = "#0e1019", bg = "#abe15b", bold = true }
      count_cut      = { fg = "#0e1019", bg = "#ff2740", bold = true }
      count_selected = { fg = "#0e1019", bg = "#67fff0", bold = true }

      border_style = { fg = "#0092ff" }
      syntect_theme = ""

      # : ]]]

      # : Status [[[
      [status]
      overall  = { fg = "#0092ff", bold = true }
      sep_left  = { open = "", close = "" }
      sep_right = { open = "", close = "" }

      progress_label  = { bold = true }
      progress_normal = { fg = "#0092ff", bg = "#1a1a2e" }
      progress_error  = { fg = "#ff2740", bg = "#1a1a2e" }

      perm_type  = { fg = "#0092ff" }
      perm_read  = { fg = "#abe15b" }
      perm_write = { fg = "#ffd242" }
      perm_exec  = { fg = "#ff2740" }
      perm_sep   = { fg = "#888888" }
      # : ]]]

      # : Mode [[[
      [mode]
      normal_main = { bg = "#0092ff", fg = "#0e1019", bold = true }
      normal_alt  = { bg = "#1a1a2e", fg = "#0092ff" }

      select_main = { bg = "#67fff0", fg = "#0e1019", bold = true }
      select_alt  = { bg = "#1a1a2e", fg = "#67fff0" }

      unset_main = { bg = "#888888", fg = "#0e1019", bold = true }
      unset_alt  = { bg = "#1a1a2e", fg = "#888888" }
      # : ]]]

      # : Input [[[
      [input]
      border   = { fg = "#0092ff" }
      title    = {}
      value    = { fg = "#fffaf4" }
      selected = { reversed = true }
      # : ]]]

      # : Tabs [[[
      [tabs]
      active   = { fg = "#0e1019", bg = "#0092ff", bold = true }
      inactive = { fg = "#888888", bg = "#1a1a2e" }
      sep_inner = { open = "", close = "" }
      # : ]]]

      # : Completion [[[
      [cmp]
      border = { fg = "#0092ff", bg = "#0e1019" }
      # : ]]]

      # : Tasks [[[
      [tasks]
      border  = { fg = "#0092ff" }
      title   = {}
      hovered = { fg = "#67fff0", underline = true }
      # : ]]]

      # : Which [[[
      [which]
      cols = 3
      mask       = { bg = "#0e1019" }
      cand       = { fg = "#67fff0" }
      rest       = { fg = "#888888" }
      desc       = { fg = "#fffaf4", bold = true }
      separator  = "  "
      separator_style = { fg = "#0092ff" }
      # : ]]]

      # : Help [[[
      [help]
      name   = { fg = "#0092ff", bold = true }
      on     = { fg = "#abe15b" }
      run    = { fg = "#67fff0" }
      desc   = { fg = "#fffaf4" }
      hover  = { reversed = true }
      footer = { fg = "#0092ff", bold = true }
      # : ]]]

      # : Spot [[[
      [spot]
      border = { fg = "#0092ff" }
      title  = { bold = true }
      cell   = { fg = "#fffaf4" }
      # : ]]]

      # : Filetype [[[
      [filetype]
      rules = [
        # Media
        { mime = "image/*",            fg = "#94e2d5" },
        { mime = "video/*",            fg = "#f9e2af" },
        { mime = "audio/*",            fg = "#f9e2af" },
        # Archives
        { mime = "application/zip",         fg = "#f5c2e7" },
        { mime = "application/gzip",        fg = "#f5c2e7" },
        { mime = "application/x-tar",       fg = "#f5c2e7" },
        { mime = "application/x-bzip*",     fg = "#f5c2e7" },
        { mime = "application/x-7z*",       fg = "#f5c2e7" },
        { mime = "application/x-rar*",      fg = "#f5c2e7" },
        { mime = "application/x-xz",        fg = "#f5c2e7" },
        # Documents
        { mime = "application/pdf",         fg = "#a6e3a1" },
        { mime = "text/markdown",           fg = "#0092ff" },
        { mime = "text/html",               fg = "#ff2740" },
        # Code
        { name = "*.nix",             fg = "#5277c3" },
        { name = "*.rs",              fg = "#ff2740" },
        { name = "*.py",              fg = "#ffd242" },
        { name = "*.js",              fg = "#ffd242" },
        { name = "*.ts",              fg = "#0092ff" },
        { name = "*.lua",             fg = "#0092ff" },
        { name = "*.toml",            fg = "#888888" },
        { name = "*.json",            fg = "#ffd242" },
        { name = "*.yaml",            fg = "#ff2740" },
        { name = "*.yml",             fg = "#ff2740" },
        # Special
        { name = "flake.lock",        fg = "#888888" },
        { name = "flake.nix",         fg = "#5277c3" },
        { name = "*.conf",            fg = "#888888" },
        { name = "Makefile",          fg = "#abe15b" },
        { name = "*.sh",              fg = "#abe15b" },
        # Executables / special
        { mime = "inode/x-empty",          fg = "#888888" },
        { is = "orphan",             fg = "#ff2740" },
      ]
      # : ]]]
    '';
  };

  # ============================================================================
  # Community themes — fetched from GitHub
  # ============================================================================

  # yazi-rs/flavors catalog (contains catppuccin-* subdirectories)
  yazi-flavors = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "flavors";
    rev = "0f9204bc948c8313963f5c9d571a82edc201f8aa";
    hash = "sha256-qWNArjWuxWL+rOjLzyIniW5hJgWiAWTCgXmMXJpaWZE=";
  };

  catppuccin-mocha = pkgs.runCommand "catppuccin-mocha.yazi" { } ''
    cp -r ${yazi-flavors}/catppuccin-mocha.yazi $out
  '';

  tokyo-night = pkgs.fetchFromGitHub {
    owner = "BennyOe";
    repo = "tokyo-night.yazi";
    rev = "8e6296f14daff24151c736ebd0b9b6cd89b02b03";
    hash = "sha256-LArhRteD7OQRBguV1n13gb5jkl90sOxShkDzgEf3PA0=";
  };

  nord = pkgs.fetchFromGitHub {
    owner = "AdithyanA2005";
    repo = "nord.yazi";
    rev = "1b1bf78deb30391095523acb94a6d9784744f92c";
    hash = "sha256-CcQBpR9fqUCXEZVznSQ1Yo8JPVE+fhhgM9QApTXaWPU=";
  };

  synthwave84 = pkgs.fetchFromGitHub {
    owner = "CFY98";
    repo = "synthwave84.yazi";
    rev = "b7bb92e406f6575979ed8fa8e602601620017d5f";
    hash = "sha256-NmBjjiae91BY0x3OxtLWiI2wqh3x+V/PwrvWqRp4QPI=";
  };

  lain = pkgs.fetchFromGitHub {
    owner = "identityapproved";
    repo = "lain.yazi";
    rev = "e2a3bb28412c92febd0152b762d3e0cf049ef139";
    hash = "sha256-oxLgkIUzTJwCypqGf7mSlmNyxflYuuzox6oocrQaCb8=";
  };

  kanagawa-paper = pkgs.fetchFromGitHub {
    owner = "melindachang";
    repo = "kanagawa-paper.yazi";
    rev = "7f3cd1d8a579cc8a38fca67fcb3cb018e4d7171c";
    hash = "sha256-QSDcHvQwUABGM76OYW2rrFcSkpo/q7e0bBZLbpCIiqw=";
  };
in
{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";

    plugins = {
      git = pkgs.yaziPlugins.git;
      full-border = pkgs.yaziPlugins.full-border;
      smart-enter = pkgs.yaziPlugins.smart-enter;
      jump-to-char = pkgs.yaziPlugins.jump-to-char;
      wl-clipboard = pkgs.yaziPlugins.wl-clipboard;
      mime-ext = pkgs.yaziPlugins.mime-ext;
      yatline = pkgs.yaziPlugins.yatline;
      yatline-githead = pkgs.yaziPlugins.yatline-githead;
    };

    flavors = {
      myargonaut = myargonaut;
      catppuccin-mocha = catppuccin-mocha;
      tokyo-night = tokyo-night;
      nord = nord;
      synthwave84 = synthwave84;
      lain = lain;
      kanagawa-paper = kanagawa-paper;
    };

    # Active theme — change this to any flavor name below
    # Available: myargonaut, catppuccin-mocha, tokyo-night, nord, synthwave84, lain, kanagawa-paper
    theme = {
      flavor = {
        dark = "myargonaut";
      };
    };

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
      preview = {
        tab_size = 4;
        max_width = 1000;
        max_height = 1000;
      };
      opener = {
        edit = [
          { run = "${pkgs.neovim}/bin/nvim \$@"; block = true; for = "unix"; }
        ];
        play = [
          { run = "${pkgs.mpv}/bin/mpv \$@"; block = false; for = "unix"; }
        ];
      };
      open = {
        prepend_rules = [
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
      };
      plugin = {
        preloaders = [
          { mime = "image/*"; run = "magick"; }
          { mime = "video/*"; run = "ffmpeg"; }
        ];
      };
    };

    keymap = {
      manager = {
        prepend_keymap = [
          { on = "f"; run = "plugin jump-to-char"; desc = "Jump to char"; }
          { on = "l"; run = "plugin smart-enter"; desc = "Enter child / open file"; }
          { on = "<Enter>"; run = "plugin smart-enter"; desc = "Enter child / open file"; }
        ];
      };
      tasks = {
        prepend_keymap = [
          { on = "l"; run = "plugin smart-enter"; desc = "Enter child / open file"; }
          { on = "<Enter>"; run = "plugin smart-enter"; desc = "Enter child / open file"; }
        ];
      };
    };
  };
}
