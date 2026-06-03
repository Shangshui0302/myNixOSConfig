{ pkgs, ... }:

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

    theme = {
      manager = {
        cwd = { fg = "#0092ff"; };
        hovered = { fg = "#0e1019"; bg = "#008df8"; };
        preview_hovered = { underline = true; };
        find_keyword = { fg = "#ffd242"; bold = true; };
        find_position = { fg = "#67fff0"; bold = true; };
        marker_selected = { fg = "#ffd242"; bold = true; };
        marker_copied = { fg = "#abe15b"; bold = true; };
        marker_cut = { fg = "#ff2740"; bold = true; };
        border = { fg = "#444444"; };
        highlight = { fg = "#ffb900"; bold = true; };
        tab_active = { fg = "#0e1019"; bg = "#0092ff"; bold = true; };
        tab_inactive = { fg = "#9d9b99"; };
        tab_width = 1;
        count_copied = { fg = "#0e1019"; bg = "#abe15b"; };
        count_cut = { fg = "#0e1019"; bg = "#ff2740"; };
        count_selected = { fg = "#0e1019"; bg = "#ffd242"; };
        syntect_theme = "base16";
      };
      status = {
        separator_open = "";
        separator_close = "";
        separator_style = { fg = "#444444"; };
        mode_normal = { fg = "#0e1019"; bg = "#abe15b"; bold = true; };
        mode_select = { fg = "#0e1019"; bg = "#ffd242"; bold = true; };
        mode_unset = { fg = "#0e1019"; bg = "#9d9b99"; bold = true; };
        progress_label = { fg = "#fffaf4"; bold = true; };
        progress_normal = { fg = "#008df8"; };
        progress_error = { fg = "#ff2740"; };
        permissions_t = { fg = "#008df8"; };
        permissions_r = { fg = "#ffd242"; };
        permissions_w = { fg = "#ff2740"; };
        permissions_x = { fg = "#abe15b"; };
        permissions_s = { fg = "#6d43a6"; };
      };
      select = {
        border = { fg = "#0092ff"; };
        active = { fg = "#ffd242"; bold = true; };
      };
      input = {
        border = { fg = "#0092ff"; };
        title = { };
        value = { };
        selected = { reversed = true; };
      };
      tasks = {
        border = { fg = "#444444"; };
        title = { };
        hovered = { underline = true; };
      };
      which = {
        mask = { bg = "#444444"; };
        cand = { fg = "#67fff0"; };
        rest = { fg = "#9d9b99"; };
        desc = { fg = "#abe15b"; };
        separator = "   ";
        separator_style = { fg = "#444444"; };
      };
      help = {
        on = { fg = "#ffd242"; };
        exec = { fg = "#6d43a6"; };
        desc = { fg = "#9d9b99"; };
        hovered = { reversed = true; };
        footer = { fg = "#444444"; };
      };
      filetype = {
        rules = [
          { mime = "image/*"; fg = "#67fff0"; }
          { mime = "video/*"; fg = "#ffb900"; }
          { mime = "audio/*"; fg = "#6d43a6"; }
          { mime = "application/zip"; fg = "#ff2740"; }
          { mime = "application/gzip"; fg = "#ff2740"; }
          { mime = "application/x-tar"; fg = "#ff2740"; }
          { mime = "application/x-bzip*"; fg = "#ff2740"; }
          { mime = "application/x-7z-compressed"; fg = "#ff2740"; }
          { mime = "application/x-rar"; fg = "#ff2740"; }
          { mime = "application/x-xz"; fg = "#ff2740"; }
          { mime = "application/pdf"; fg = "#ff2740"; }
          { mime = "text/markdown"; fg = "#008df8"; }
          { mime = "text/*"; fg = "#abe15b"; }
          { name = "*.nix"; fg = "#5277c3"; }
          { name = "*.rs"; fg = "#ff2740"; }
          { name = "*.py"; fg = "#ffd242"; }
          { name = "*.js"; fg = "#ffb900"; }
          { name = "*.ts"; fg = "#0092ff"; }
          { name = "*.json"; fg = "#ffd242"; }
          { name = "*.toml"; fg = "#6d43a6"; }
          { name = "*.yaml"; fg = "#6d43a6"; }
        ];
      };
      spot = {
        border = { fg = "#444444"; };
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
          { name = "*.md"; use = "edit"; }
          { name = "*.nix"; use = "edit"; }
          { name = "*.txt"; use = "edit"; }
          { name = "*.rs"; use = "edit"; }
          { name = "*.py"; use = "edit"; }
          { name = "*.js"; use = "edit"; }
          { name = "*.ts"; use = "edit"; }
          { name = "*.json"; use = "edit"; }
          { name = "*.toml"; use = "edit"; }
          { name = "*.yaml"; use = "edit"; }
          { name = "*.lua"; use = "edit"; }
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
