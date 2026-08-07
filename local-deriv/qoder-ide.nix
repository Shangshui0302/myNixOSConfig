{ pkgs }:

pkgs.stdenv.mkDerivation rec {
  pname = "qoder-ide";
  version = "1.22.1";

  src = pkgs.fetchurl {
    url = "https://download.qoder.com/release/latest/qoder_amd64.deb";
    sha256 = "4c9a4f1a4d0d052c1b83c0a508bce0ad56a58c68286008c2011d755a1636144b";
  };

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
    pkgs.dpkg
    pkgs.makeWrapper
  ];

  buildInputs = with pkgs; [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libX11
    libxcb
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxkbcommon
    libxkbfile
    libgbm
    nspr
    nss
    pango
    systemdLibs
  ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    # Extract data.tar.xz directly (dpkg-deb -x preserves setuid on
    # chrome-sandbox, which the sandboxed build env forbids)
    mkdir -p deb
    (cd deb && ${pkgs.binutils}/bin/ar x "$src")
    mkdir -p deb/extracted
    tar -xf deb/data.tar.xz -C deb/extracted --no-same-owner
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,share/applications,share/icons/hicolor/scalable/apps}
    cp -r deb/extracted/usr/share/qoder $out/share/
    cp deb/extracted/usr/share/pixmaps/Qoder.png $out/share/icons/hicolor/scalable/apps/
    chmod +x $out/share/qoder/qoder $out/share/qoder/chrome-sandbox
    substitute deb/extracted/usr/share/applications/qoder.desktop \
      $out/share/applications/qoder.desktop \
      --replace-fail "/usr/share/qoder/qoder" "qoder"
    substitute deb/extracted/usr/share/applications/qoder-url-handler.desktop \
      $out/share/applications/qoder-url-handler.desktop \
      --replace-fail "/usr/share/qoder/qoder" "qoder"
    makeWrapper $out/share/qoder/qoder $out/bin/qoder \
      --add-flags "--no-sandbox --disable-gpu-sandbox --password-store=gnome-libsecret"
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Qoder — Agentic coding platform for real software";
    homepage = "https://qoder.com";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
