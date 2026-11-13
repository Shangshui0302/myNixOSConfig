{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  openssl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  gtk3,
  webkitgtk_4_1,
  glib-networking,
  libayatana-appindicator,
  libX11,
  libXi,
  curl,
  zlib,
  vulkan-loader,
  gst_all_1,
  xdg-utils,
}:

let
  version = "0.7.0-beta.3";
  # Only the Rust/HTML interface needs the compositor patch. Keep the official
  # Swift helper, llama.cpp, PDFium and FFmpeg from the matching release below.
  shell = rustPlatform.buildRustPackage {
    pname = "digup-shell";
    inherit version;
    src = fetchFromGitHub {
      owner = "ARahim3";
      repo = "DigUp";
      tag = "v${version}";
      hash = "sha256-KXMIA/eMLJrhPf31BwCj+RY3Rod9LbMG1wCmiLbsDGc=";
    };
    cargoRoot = "shell/src-tauri";
    buildAndTestSubdir = "shell/src-tauri";
    cargoHash = "sha256-k0ijjdZzwWb3M+Qbj5+ozQrzTOMljgz1RBGj4hCJL0E=";
    patches = [ ./digup-compositor-panel.patch ];
    buildFeatures = [ "tauri/custom-protocol" ];
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [
      gtk3
      webkitgtk_4_1
      openssl
      libX11
      libXi
    ];
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "digup";
  inherit version;

  src = fetchurl {
    url = "https://github.com/ARahim3/DigUp/releases/download/v${finalAttrs.version}/DigUp_${finalAttrs.version}_amd64.deb";
    hash = "sha256-gTluY/2SYB3/5LZca5ouSWvP2i0YjrJCIKJDG2jgO9g=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    gtk3
    webkitgtk_4_1
    glib-networking
    curl
    zlib
    vulkan-loader
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
  ];
  # Tauri's tray and X11 input handling load these outside ELF NEEDED entries.
  runtimeDependencies = [
    libayatana-appindicator
    libX11
    libXi
  ];

  sourceRoot = "root";
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r usr/bin usr/lib usr/share $out/
    install -m755 ${shell}/bin/digup-shell $out/bin/digup-shell
    substituteInPlace $out/share/applications/DigUp.desktop \
      --replace-fail 'Exec=digup-shell' "Exec=$out/bin/digup-shell"
    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(--prefix PATH : ${lib.makeBinPath [ xdg-utils ]})
  '';

  meta = {
    description = "On-device semantic search for documents, pictures, recordings and code";
    homepage = "https://github.com/ARahim3/DigUp";
    changelog = "https://github.com/ARahim3/DigUp/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    sourceProvenance = [
      lib.sourceTypes.fromSource
      lib.sourceTypes.binaryNativeCode
    ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "digup-shell";
  };
})
