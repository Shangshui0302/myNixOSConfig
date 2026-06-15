{ pkgs }:
pkgs.stdenv.mkDerivation rec {
  pname = "aionui";
  version = "2.1.18";

  src = pkgs.fetchurl {
    url = "https://github.com/iOfficeAI/AionUi/releases/download/v${version}/AionUi-${version}-linux-amd64.deb";
    sha256 = "1ny3znl7g10j6kiy65dd36ay3dcw2z08la4b6yc78bjvqx99ifms";
  };

  nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];
  buildInputs = with pkgs; [
    stdenv.cc.cc.lib
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

    substitute usr/share/applications/AionUi.desktop \
      $out/share/applications/${pname}.desktop \
      --replace-fail "/opt/AionUi/AionUi" "${pname}" \
      --replace-fail "Icon=aionui" "Icon=${pname}"

    cp usr/share/icons/hicolor/1024x1024/apps/AionUi.png \
      $out/share/icons/hicolor/1024x1024/apps/${pname}.png

    makeWrapper $out/lib/${pname}/AionUi $out/bin/${pname} \
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
