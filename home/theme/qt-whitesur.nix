{
  lib,
  pkgs,
  ...
}:
let
  runAfter = import ./run-after.nix lib;
in
{
  # Qt installs both engines; static theme data and runtime selection have
  # separate owners. Do not enable qt.kvantum's declarative selector module.
  qt = {
    enable = true;
    style.name = "kvantum";
  };

  # Dolphin and other KDE consumers select these semantic palettes by name.
  xdg.dataFile =
    (lib.genAttrs [ "WhiteSur" "WhiteSurDark" ] (name: {
      # Reclaim legacy user copies so they cannot block the entire HM activation.
      force = true;
      target = "color-schemes/${name}.colors";
      source = "${pkgs.whitesur-kde}/share/color-schemes/${name}.colors";
    }))
    // {
      # nixpkgs' Qt5/Qt6 Kvantum supports XDG data locations. Both variants live
      # here; the writable selector stays in XDG config.
      "Kvantum/WhiteSur".source = "${pkgs.whitesur-kde}/share/Kvantum/WhiteSur";
    };

  home.activation.initializeWhiteSurQt = runAfter "initializeWhiteSurQt" [ "writeBoundary" "linkGeneration" ] ''
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
