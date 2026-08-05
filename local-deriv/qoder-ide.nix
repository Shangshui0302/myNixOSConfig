{ pkgs }:

pkgs.stdenv.mkDerivation rec {
  pname = "qoder-ide";
  version = "1.10.0";

  src = pkgs.fetchurl {
    url = "https://ide.qoder.com.cn/qoder/release/lastest/qoder-cn_amd64.deb";
    sha256 = "0l9qynrjdk56n6l01xrhnh0c1k1y9hn1ikzmww73bfz7p7ks688b";
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
    cp -r deb/extracted/usr/share/qoder-cn $out/share/
    cp deb/extracted/usr/share/pixmaps/QoderCN.png $out/share/icons/hicolor/scalable/apps/
    chmod +x $out/share/qoder-cn/qoder-cn $out/share/qoder-cn/chrome-sandbox
    substitute deb/extracted/usr/share/applications/qoder-cn.desktop \
      $out/share/applications/qoder-cn.desktop \
      --replace-fail "/usr/share/qoder-cn/qoder-cn" "qoder-cn"
    makeWrapper $out/share/qoder-cn/qoder-cn $out/bin/qoder-cn \
      --add-flags "--no-sandbox --disable-gpu-sandbox"
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Qoder CN — Agentic coding platform for real software";
    homepage = "https://qoder.com";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
