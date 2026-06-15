{ pkgs, lib, ... }: {
  home.packages = with pkgs; [
    libreoffice-fresh
    onlyoffice-desktopeditors
    obsidian

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

  home.activation.onlyofficeFonts = ''
    mkdir -p $HOME/.local/share/fonts
    for font_dir in \
      ${pkgs.noto-fonts-cjk-sans}/share/fonts \
      ${pkgs.noto-fonts-cjk-serif}/share/fonts \
      ${pkgs.wqy_microhei}/share/fonts \
      ${pkgs.wqy_zenhei}/share/fonts; do
      find "$font_dir" -name "*.ttf" -o -name "*.otf" | \
        while read f; do
          cp -n "$f" $HOME/.local/share/fonts/ 2>/dev/null || true
          chmod 644 "$HOME/.local/share/fonts/$(basename "$f")" 2>/dev/null || true
        done
    done
    $DRY_RUN_CMD ${pkgs.fontconfig}/bin/fc-cache -f $HOME/.local/share/fonts/
  '';

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"   = "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"         = "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "onlyoffice-desktopeditors.desktop";
      "application/msword"                                                         = "onlyoffice-desktopeditors.desktop";
      "application/vnd.ms-excel"                                                   = "onlyoffice-desktopeditors.desktop";
      "application/vnd.ms-powerpoint"                                              = "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.text"                                   = "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.spreadsheet"                            = "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.presentation"                           = "onlyoffice-desktopeditors.desktop";
    };
  };
}
