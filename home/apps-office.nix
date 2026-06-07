{ pkgs, ... }:

{
  home.packages = with pkgs; [
    obsidian libreoffice

    (pkgs.symlinkJoin {
      name = "wpsoffice-wrapped";
      paths = [ pkgs.wpsoffice ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        for bin in wps wpp et wpspdf; do
          wrapProgram $out/bin/$bin \
            --set QT_SCALE_FACTOR 2 \
            --set QT_AUTO_SCREEN_SCALE_FACTOR 0
        done
        for desktop in $out/share/applications/wps-office-*.desktop; do
          name=$(basename "$desktop")
          rm "$desktop"
          cp "${pkgs.wpsoffice}/share/applications/$name" "$desktop"
          substituteInPlace "$desktop" \
            --replace-fail '${pkgs.wpsoffice}' "$out"
        done
      '';
    })
  ];
}
