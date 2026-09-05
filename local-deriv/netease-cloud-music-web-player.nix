{ pkgs }:
pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "netease-cloud-music-web-player";
  version = "1.6.1";

  src = pkgs.fetchurl {
    url = "https://github.com/feng-yifan/Netease-Cloud-Music-Web-Player/releases/download/${finalAttrs.version}/netease-cloud-music-web-player-${finalAttrs.version}.tar.gz";
    hash = "sha256-3unzEwrk1u1x0iILkjkHSBIKQINKSg5dg5SNN002ElQ=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -d "$out/bin" "$out/lib/${finalAttrs.pname}" \
      "$out/share/applications" "$out/share/icons/hicolor/scalable/apps"

    install -Dm644 app.asar "$out/lib/${finalAttrs.pname}/app.asar"
    install -Dm644 netease-cloud-music.svg \
      "$out/share/icons/hicolor/scalable/apps/${finalAttrs.pname}.svg"

    substitute netease-cloud-music-web-player.desktop \
      "$out/share/applications/${finalAttrs.pname}.desktop" \
      --replace-fail "/usr/bin/${finalAttrs.pname}" "${finalAttrs.pname}"

    makeWrapper ${pkgs.electron}/bin/electron "$out/bin/${finalAttrs.pname}" \
      --add-flags "$out/lib/${finalAttrs.pname}/app.asar" \
      --add-flags "--no-sandbox --disable-gpu-sandbox --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --password-store=basic" \
      --set-default ELECTRON_FORCE_IS_PACKAGED 1
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Unofficial NetEase Cloud Music web player desktop client";
    homepage = "https://github.com/feng-yifan/Netease-Cloud-Music-Web-Player";
    license = licenses.mit;
    mainProgram = finalAttrs.pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryBytecode ];
  };
})
