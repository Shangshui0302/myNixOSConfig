programs.starship = {
enable = true;
enableBashIntegration = true;
enableFishIntegration = true;

settings = {
add_newline = true;
command_timeout = 2000;

```
format = ''
  $os$custom.distrobox$shell$username$hostname
  $directory
  $git_branch$git_status$git_metrics
  $nix_shell$python$rust$nodejs$docker_context
  $line_break
  $time $battery $cmd_duration
  $line_break
  $character
'';

line_break = "\n";

os = {
  disabled = false;
  style = "#5277c3 bold";
  format = "[$symbol ]($style)";
  symbols = {
    NixOS = "";
    Arch = "";
    Ubuntu = "";
    Fedora = "";
    Debian = "";
    Linux = "";
  };
};

custom.distrobox = {
  when = "[ -n \"$DISTROBOX_ID\" ]";
  command = "echo $DISTROBOX_ID";
  style = "#ff88cc bold";
  format = "[📦 $output ]($style)";
};

shell = {
  disabled = false;
  style = "#cccccc bold";
  bash_indicator = "";
  fish_indicator = "󰈺";
  zsh_indicator = "󰰶";
  format = "[$indicator ]($style)";
};

username = {
  show_always = true;
  style_user = "#abe15b bold";
  style_root = "#ff2740 bold";
  format = "[$user]($style)";
};

hostname = {
  ssh_only = false;
  style = "#5fafd7 bold";
  format = "[@$hostname ]($style)";
  trim_at = ".local";
};

directory = {
  style = "#33adff bold";
  read_only = "󰌾";
  read_only_style = "#ff2740";
  truncation_length = 4;
  truncate_to_repo = true;
  home_symbol = "~";
  format = "[📁 $path]($style)[$read_only]($read_only_style)";
};

git_branch = {
  symbol = " ";
  style = "#bb88ee bold";
  format = "[$symbol$branch(:$remote_branch)]($style)";
  truncation_length = 20;
  truncation_symbol = "…";
};

git_status = {
  style = "#ffd242 bold";
  format = "([$all_status$ahead_behind]($style)[ ](#ffffff))";

  ahead = "⇡${count}";
  behind = "⇣${count}";
  diverged = "⇕⇡${ahead_count}⇣${behind_count}";
  conflicted = "=${count}";
  untracked = "?${count}";
  stashed = "󰏗${count}";
  modified = "!${count}";
  staged = "+${count}";
  renamed = "»${count}";
  deleted = "✘${count}";
};

git_metrics = {
  disabled = false;
  added_style = "#abe15b bold";
  deleted_style = "#ff2740 bold";
  only_nonzero_diffs = true;
  format =
    "([+$added]($added_style)[/](#ffffff)[-$deleted]($deleted_style))";
};

nix_shell = {
  symbol = "";
  style = "#5277c3 bold";
  format = "[$symbol $state ]($style)";
  impure_msg = "[impure](#ff2740 bold)";
  pure_msg = "[pure](#abe15b bold)";
  unknown_msg = "[?](#ffd242 bold)";
};

python = {
  symbol = "";
  style = "#ffd242 bold";
  format = "[$symbol $version( ($virtualenv)) ]($style)";
  python_binary = [ "python3" "python" ];
};

nodejs = {
  symbol = "";
  style = "#abe15b bold";
  format = "[$symbol $version ]($style)";
};

rust = {
  symbol = "󱘗";
  style = "#ff2740 bold";
  format = "[$symbol $version ]($style)";
};

docker_context = {
  symbol = "";
  style = "#0092ff bold";
  format = "[$symbol $context ]($style)";
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
```

};
};
