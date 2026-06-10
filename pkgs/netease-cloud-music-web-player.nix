{ pkgs, src }:
pkgs.stdenv.mkDerivation rec {
  pname = "netease-cloud-music-web-player";
  version = "1.6.0";

  inherit src;

  sourceRoot = ".";

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/{bin,lib/${pname},share/{applications,icons/hicolor/scalable/apps}}

    cp app.asar $out/lib/${pname}/
    cp netease-cloud-music.svg $out/share/icons/hicolor/scalable/apps/

    substitute netease-cloud-music-web-player.desktop \
      $out/share/applications/${pname}.desktop \
      --replace-fail "/usr/bin/${pname}" "${pname}" \
      --replace-fail "Icon=netease-cloud-music" "Icon=netease-cloud-music"

    makeWrapper ${pkgs.electron}/bin/electron $out/bin/${pname} \
      --add-flags "$out/lib/${pname}/app.asar" \
      --add-flags "--no-sandbox --disable-gpu-sandbox --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --password-store=basic" \
      --set-default ELECTRON_FORCE_IS_PACKAGED 1
  '';

  meta = with pkgs.lib; {
    description = "Unofficial NetEase Cloud Music web player desktop client";
    homepage = "https://github.com/feng-yifan/Netease-Cloud-Music-Web-Player";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
