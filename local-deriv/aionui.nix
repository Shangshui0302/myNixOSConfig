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

    # AionCore's prepare_runtime_files() expects to create cache/ and tools/
    # inside the bundled Node.js directory. Pre-create them so the Nix store
    # doesn't block it (store is 0555, non-root user gets EACCES).
    for node_dir in $out/lib/${pname}/resources/bundled-aioncore/linux-x64/managed-resources/node/node-v*/; do
      mkdir -p "$node_dir/cache" "$node_dir/tools/global/bin"
    done

    substitute usr/share/applications/AionUi.desktop \
      $out/share/applications/${pname}.desktop \
      --replace-fail "/opt/AionUi/AionUi" "${pname}" \
      --replace-fail "Icon=aionui" "Icon=${pname}"

    cp usr/share/icons/hicolor/1024x1024/apps/AionUi.png \
      $out/share/icons/hicolor/1024x1024/apps/${pname}.png

    makeWrapper $out/lib/${pname}/AionUi $out/bin/${pname} \
      --add-flags "--no-sandbox --disable-gpu-sandbox --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --password-store=basic"
  '';

  # Nix fixup normalises perms to 0555/0444. AionCore needs to write to
  # blank npmrc files and the cache/tools dirs at runtime, so re-open them.
  postFixup = let
    nodeBase = "lib/${pname}/resources/bundled-aioncore/linux-x64/managed-resources/node";
  in ''
    for node_dir in "$out/${nodeBase}"/node-v*/; do
      chmod 0777 "$node_dir/cache" "$node_dir/tools" "$node_dir/tools/global" "$node_dir/tools/global/bin" 2>/dev/null || true
      chmod 0666 "$node_dir/blank_user_npmrc" "$node_dir/blank_global_npmrc" 2>/dev/null || true
    done
  '';

  meta = with pkgs.lib; {
    description = "AI agent cowork platform — desktop hub for 30+ AI platforms and 20+ CLI agents";
    homepage = "https://github.com/iOfficeAI/AionUi";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "aionui";
  };
}
