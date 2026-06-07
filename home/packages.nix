{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Shell tools
    starship eza zoxide fzf bat fd blesh

    # System utils
    wget curl pciutils usbutils nix-index
    htop steam-run

    # Network diag
    dnsutils iputils tcpdump mtr nmap iperf3 ethtool iptables

    # Archiver
    ouch p7zip unzip file-roller xarchiver

    # Icons & Themes
    papirus-icon-theme gnome-themes-extra adw-gtk3

    # File manager
    nemo nemo-emblems nemo-fileroller

    # Image & Thumbnails
    loupe mpv ffmpegthumbnailer tumbler

    # Wayland utils
    awww swaynotificationcenter libnotify
    grim slurp wl-clipboard grimblast swappy
    waybar wofi
  ] ++ [
    (pkgs.writeShellScriptBin "screenshot" ''
      dir="$HOME/Pictures/Screenshots/$(date +%Y-%m)"
      mkdir -p "$dir"
      case "$1" in
        area)
          tmp=$(mktemp /tmp/screenshot-XXXXXX.png)
          trap "rm -f $tmp" EXIT
          ${pkgs.grimblast}/bin/grimblast save area "$tmp" || exit 1
          ${pkgs.swappy}/bin/swappy -f "$tmp"
          file="$dir/$(date +%Y-%m-%d-%H%M%S).png"
          cp "$tmp" "$file"
          ${pkgs.wl-clipboard}/bin/wl-copy < "$file"
          ;;
        *)
          file="$dir/$(date +%Y-%m-%d-%H%M%S).png"
          ${pkgs.grimblast}/bin/grimblast save "$1" "$file"
          ${pkgs.wl-clipboard}/bin/wl-copy < "$file"
          ;;
      esac
    '')
  ];
}
