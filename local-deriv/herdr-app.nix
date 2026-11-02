{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  libxcb,
  libxkbcommon,
  wayland,
  libglvnd,
  vulkan-loader,
  callPackage,
  herdr-core ? callPackage ./herdr-core.nix { },
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "herdr-app";
  version = "0.1.11";
  src = fetchurl {
    url = "https://releases.herdr.dev/app/${finalAttrs.version}/herdr-app-linux-x86_64.tar.gz";
    hash = "sha256-Ro/zFqJvxMLGOPEMWNLeNTyCXKxNhG+iVMYSlBQXRKM=";
  };
  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];
  buildInputs = [
    libxcb
    libxkbcommon
    stdenv.cc.cc.lib
  ];
  # GPUI loads these by name rather than linking them as NEEDED entries.
  runtimeDependencies = [
    wayland
    libglvnd
    vulkan-loader
  ];
  dontBuild = true;
  desktopItems = [
    (makeDesktopItem {
      name = "herdr-app";
      desktopName = "Herdr";
      comment = "Terminals and coding agents that keep running";
      exec = "herdr-app";
      icon = "herdr-app";
      categories = [ "Development" ];
      startupWMClass = "herdr-app";
    })
  ];
  installPhase = ''
    runHook preInstall
    install -Dm755 herdr-app $out/bin/herdr-app
    # Keep the icon in the standard location, not beside the binary: upstream
    # only enables app self-updates for its own binary-plus-icon release layout.
    install -Dm644 herdr-app.svg $out/share/icons/hicolor/scalable/apps/herdr-app.svg
    install -Dm644 LICENSE $out/share/licenses/herdr-app/LICENSE
    install -Dm644 THIRD-PARTY-NOTICES $out/share/licenses/herdr-app/THIRD-PARTY-NOTICES
    wrapProgram $out/bin/herdr-app --prefix PATH : ${lib.makeBinPath [ herdr-core ]}
    runHook postInstall
  '';
  meta = {
    description = "Desktop workspace for terminals and coding agents";
    homepage = "https://github.com/herdrdev/herdr-app";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "herdr-app";
  };
})
