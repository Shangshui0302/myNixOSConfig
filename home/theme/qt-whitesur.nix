{
  lib,
  pkgs,
  ...
}:
{
  # Install both Qt engines and the immutable WhiteSur light/dark assets. The
  # desktop's runtime owns only kvantum.kvconfig, selecting the appropriate mode.
  qt = {
    enable = true;
    style.name = "kvantum";
    kvantum = {
      enable = true;
      themes = [ pkgs.whitesur-kde ];
    };
  };

  # Dolphin and other KDE consumers select these semantic palettes by name.
  xdg.dataFile = lib.genAttrs [ "WhiteSur" "WhiteSurDark" ] (name: {
    target = "color-schemes/${name}.colors";
    source = "${pkgs.whitesur-kde}/share/color-schemes/${name}.colors";
  });

  home.activation.initializeWhiteSurQt = lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] ''
    selector="$HOME/.config/Kvantum/kvantum.kvconfig"
    # Reclaim the old immutable HM selector during migration. Later activations
    # preserve the mode chosen by the active desktop's synchronizer.
    if [ ! -e "$selector" ] || ${pkgs.gnugrep}/bin/grep -q 'theme=MaterialAdw' "$selector"; then
      mkdir -p "$HOME/.config/Kvantum"
      temporary="$(${pkgs.coreutils}/bin/mktemp "$HOME/.config/Kvantum/.kvantum.XXXXXX")"
      printf '[General]\ntheme=WhiteSurDark\n' > "$temporary"
      ${pkgs.coreutils}/bin/mv -f "$temporary" "$selector"
    fi
  '';
}
