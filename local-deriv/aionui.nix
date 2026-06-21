{ pkgs }:
pkgs.stdenv.mkDerivation rec {
  pname = "aionui";
  version = "2.1.21";

  src = pkgs.fetchurl {
    url = "https://github.com/iOfficeAI/AionUi/releases/download/v${version}/AionUi-${version}-linux-amd64.deb";
    sha256 = "07n137ss84bpnnmzgpsqknnq5ymgf6wqsp0xc28bz1b13x7m8lb5";
  };

  nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];
  buildInputs = with pkgs; [
    stdenv.cc.cc.lib
    alsa-lib
    libsecret
    libxkbcommon
    libxcb
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libXrender
    libdrm
    mesa
    cairo
    pango
    atk
    gtk3
    nss
    nspr
    cups
    dbus
  ];

  unpackPhase = ''
    ar x $src
    tar xf data.tar.xz
  '';

  installPhase = ''
    mkdir -p $out/{bin,lib/${pname},share/{applications,icons/hicolor/1024x1024/apps}}

    cp -r opt/AionUi/* $out/lib/${pname}/
    find $out/lib/${pname} -path "*/claude-agent-sdk-linux-x64-musl/claude" -delete

    substitute usr/share/applications/AionUi.desktop \
      $out/share/applications/${pname}.desktop \
      --replace-fail "/opt/AionUi/AionUi" "${pname}" \
      --replace-fail "Icon=aionui" "Icon=${pname}"

    cp usr/share/icons/hicolor/1024x1024/apps/AionUi.png \
      $out/share/icons/hicolor/1024x1024/apps/${pname}.png

    # AionCore's prepare_runtime_files() needs to write inside the bundled
    # Node.js directory. The Nix store is read-only, so materialise a writable
    # copy under ~/.cache/aionui/ at first launch and point AIONUI_BUNDLED_MANAGED_RESOURCES there.
    managed_src="$out/lib/${pname}/resources/bundled-aioncore/linux-x64/managed-resources"
    {
      echo '#!/bin/sh'
      echo "RUNTIME_DIR=\"\$HOME/.cache/aionui/managed-resources\""
      echo "STORE_DIR=\"$managed_src\""
      echo "VERSION_FILE=\"\$RUNTIME_DIR/.version\""
      echo "if [ ! -f \"\$VERSION_FILE\" ] || [ \"\$(cat \"\$VERSION_FILE\")\" != \"${version}\" ]; then"
      echo "  rm -rf \"\$RUNTIME_DIR\""
      echo "  mkdir -p \"\$RUNTIME_DIR\""
      echo "  cp -r \"\$STORE_DIR\"/* \"\$RUNTIME_DIR\"/"
      echo "  chmod -R u+w \"\$RUNTIME_DIR\""
      echo "  echo \"${version}\" > \"\$VERSION_FILE\""
      echo "fi"
      echo "export AIONUI_BUNDLED_MANAGED_RESOURCES=\"\$RUNTIME_DIR\""
    } > $out/lib/${pname}/setup-runtime
    chmod +x $out/lib/${pname}/setup-runtime

    makeWrapper $out/lib/${pname}/AionUi $out/bin/${pname} \
      --run "source $out/lib/${pname}/setup-runtime" \
      --add-flags "--no-sandbox --disable-gpu-sandbox --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --password-store=basic"
  '';

  meta = with pkgs.lib; {
    description = "AI agent cowork platform — desktop hub for 30+ AI platforms and 20+ CLI agents";
    homepage = "https://github.com/iOfficeAI/AionUi";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "aionui";
  };
}
