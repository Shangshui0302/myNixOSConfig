{ pkgs, ... }:

{
  services.udiskie.enable = true;

  services.flatpak.packages = [
    "io.github.wh201906.serialtest"
  ];

  home.packages = with pkgs; [
    fastfetch
    wget
    curl
    pciutils
    usbutils
    nix-index
    steam-run
    rclone
    ventoy-full
    imagemagick
    poppler-utils
  ];

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "blackgolden";
      theme_background = false;
      truecolor = true;
      force_tty = false;
      presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty";
      vim_keys = false;
      rounded_corners = true;
      terminal_sync = true;
      graph_symbol = "braille";
      shown_boxes = "cpu mem net proc";
      update_ms = 2000;
      proc_sorting = "cpu lazy";
      proc_reversed = false;
      proc_tree = false;
      proc_colors = true;
      proc_gradient = true;
      proc_mem_bytes = true;
      proc_cpu_graphs = true;
      cpu_invert_lower = true;
      cpu_single_graph = false;
      show_uptime = true;
      check_temp = true;
      cpu_sensor = "Auto";
      show_coretemp = true;
      temp_scale = "celsius";
      base_10_sizes = false;
      show_cpu_freq = true;
      clock_format = "%X";
      background_update = true;
      mem_graphs = true;
      show_swap = true;
      swap_disk = true;
      show_disks = true;
      only_physical = true;
      use_fstab = true;
      show_io_stat = true;
      io_mode = false;
      net_download = 100;
      net_upload = 100;
      net_auto = true;
      net_sync = true;
      show_battery = true;
      selected_battery = "Auto";
      show_battery_watts = true;
      log_level = "WARNING";
      nvml_measure_pcie_speeds = true;
      rsmi_measure_pcie_speeds = true;
      gpu_mirror_graph = true;
      shown_gpus = "nvidia amd intel";
    };
    themes.blackgolden = ''
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
  };
}
