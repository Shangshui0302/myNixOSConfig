{ pkgs, ... }:

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
        { mime = "image/*", fg = "#94e2d5" },
        { mime = "video/*", fg = "#f9e2af" },
        { mime = "audio/*", fg = "#f9e2af" },
        { mime = "application/zip", fg = "#f5c2e7" },
        { mime = "application/gzip", fg = "#f5c2e7" },
        { mime = "application/x-tar", fg = "#f5c2e7" },
        { mime = "application/x-7z*", fg = "#f5c2e7" },
        { mime = "application/x-rar*", fg = "#f5c2e7" },
        { mime = "application/pdf", fg = "#a6e3a1" },
        { mime = "text/markdown", fg = "#abe15b" },
        { mime = "text/html", fg = "#ff2740" },
        { url = "*.nix", fg = "#8ce10b" },
        { url = "*.rs", fg = "#ff2740" },
        { url = "*.py", fg = "#ffd242" },
        { url = "*.js", fg = "#ffd242" },
        { url = "*.ts", fg = "#00d8eb" },
        { url = "*.lua", fg = "#00d8eb" },
        { url = "*.toml", fg = "#888888" },
        { url = "*.json", fg = "#ffd242" },
        { url = "*.yaml", fg = "#ff2740" },
        { url = "*.yml", fg = "#ff2740" },
        { url = "flake.lock", fg = "#888888" },
        { url = "flake.nix", fg = "#8ce10b" },
        { url = "*.conf", fg = "#888888" },
        { url = "Makefile", fg = "#abe15b" },
        { url = "*.sh", fg = "#abe15b" },
        { mime = "inode/x-empty", fg = "#888888" },
        { url = "*", is = "orphan", fg = "#ff2740" }
      ]

      [icon]
      prepend_dirs = [
        { name = "Desktop", text = "", fg = "#8ce10b" },
        { name = "Documents", text = "󱔗", fg = "#8ce10b" },
        { name = "Downloads", text = "", fg = "#8ce10b" },
        { name = "Pictures", text = "", fg = "#8ce10b" },
        { name = "Videos", text = "󰑈", fg = "#8ce10b" },
        { name = "Music", text = "󰝚", fg = "#8ce10b" },
        { name = "home", text = "", fg = "#8ce10b" },
        { name = "Projects", text = "", fg = "#8ce10b" },
        { name = "myNixOSConfig", text = "󱄅", fg = "#8ce10b" },
        { name = ".git", text = "", fg = "#abe15b" },
        { name = ".config", text = "", fg = "#8ce10b" },
        { name = ".cache", text = "", fg = "#888888" },
        { name = ".local", text = "", fg = "#888888" },
        { name = "node_modules", text = "", fg = "#888888" }
      ]
      prepend_exts = [
        { name = "nix", text = "󰋗", fg = "#8ce10b" },
        { name = "lock", text = "󰋗", fg = "#888888" },
        { name = "rs", text = "", fg = "#ff2740" },
        { name = "py", text = "", fg = "#ffd242" },
        { name = "js", text = "", fg = "#ffd242" },
        { name = "ts", text = "", fg = "#00d8eb" },
        { name = "lua", text = "", fg = "#00d8eb" },
        { name = "json", text = "", fg = "#ffd242" },
        { name = "yaml", text = "", fg = "#ff2740" },
        { name = "yml", text = "", fg = "#ff2740" },
        { name = "toml", text = "", fg = "#888888" },
        { name = "md", text = "󰉿", fg = "#abe15b" },
        { name = "txt", text = "󰉿", fg = "#888888" },
        { name = "sh", text = "", fg = "#abe15b" },
        { name = "bash", text = "", fg = "#abe15b" },
        { name = "fish", text = "", fg = "#abe15b" },
        { name = "conf", text = "", fg = "#888888" },
        { name = "css", text = "", fg = "#00d8eb" },
        { name = "html", text = "", fg = "#ff2740" },
        { name = "svg", text = "󰜘", fg = "#ffd242" },
        { name = "png", text = "󰉏", fg = "#94e2d5" },
        { name = "jpg", text = "󰉏", fg = "#94e2d5" },
        { name = "jpeg", text = "󰉏", fg = "#94e2d5" },
        { name = "gif", text = "󰉏", fg = "#94e2d5" },
        { name = "mp4", text = "", fg = "#f9e2af" },
        { name = "mkv", text = "", fg = "#f9e2af" },
        { name = "mp3", text = "", fg = "#f9e2af" },
        { name = "flac", text = "", fg = "#f9e2af" },
        { name = "wav", text = "", fg = "#f9e2af" },
        { name = "zip", text = "󰛫", fg = "#f5c2e7" },
        { name = "tar.gz", text = "󰛫", fg = "#f5c2e7" },
        { name = "tar.xz", text = "󰛫", fg = "#f5c2e7" },
        { name = "rar", text = "󰛫", fg = "#f5c2e7" },
        { name = "7z", text = "󰛫", fg = "#f5c2e7" },
        { name = "pdf", text = "", fg = "#a6e3a1" },
        { name = "desktop", text = "", fg = "#8ce10b" }
      ]
      prepend_conds = [
        { if = "dir & hovered", text = "", fg = "#abe15b" },
        { if = "dir", text = "", fg = "#8ce10b" },
        { if = "exec", text = "", fg = "#abe15b" },
        { if = "!dir & !exec", text = "", fg = "#888888" }
      ]
    '';
  };

in
{

  # ---- yazi ----
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";

    initLua = ''require("starship"):setup()'';

    plugins = {
      smart-enter = pkgs.yaziPlugins.smart-enter;
      jump-to-char = pkgs.yaziPlugins.jump-to-char;
      starship = pkgs.yaziPlugins.starship;
    };

    flavors = {
      inherit myargonaut;
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
        { on = "\\"; run = "cd /run/media/lishangshui"; desc = "Go to removable media"; }
      ];
      tasks.prepend_keymap = [
        { on = "l"; run = "plugin smart-enter"; desc = "Enter child / open file"; }
        { on = "<Enter>"; run = "plugin smart-enter"; desc = "Enter child / open file"; }
      ];
    };
  };
}
