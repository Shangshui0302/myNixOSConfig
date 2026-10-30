{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  qt6,
  qt6Packages,
  qrencode,
  taglib,
  gst_all_1,
  glib-networking,
  nodejs,
  makeWrapper,
}:

stdenv.mkDerivation {
  pname = "kmusic";
  version = "0.1.0-unstable-2026-10-24";

  src = fetchFromGitHub {
    owner = "NextKde";
    repo = "KMusic";
    rev = "ad0222d4404a166a1607e2967f3201cea64111c5";
    hash = "sha256-dYIBOzlMuECIssnGNNB6ugvUi3M6QO0u8pe0UiX2P/U=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    qt6.wrapQtAppsHook
    makeWrapper
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qt5compat
    qt6.qtsvg
    qt6.qtwayland
    qt6Packages.qtkeychain
    qrencode
    taglib
    glib-networking
  ]
  ++ (with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
    gst-libav
  ]);

  postInstall = ''
    # The pinned CMake install rules omit the existing LX source helper.
    # Keep its CommonJS source outside providers/, whose package is an ES module.
    install -Dm644 ../src/LxSourceHost.js $out/libexec/kmusic/LxSourceHost.cjs
    makeWrapper ${lib.getExe nodejs} $out/bin/kos-music-lx-source-host \
      --add-flags "$out/libexec/kmusic/LxSourceHost.cjs"

    qtWrapperArgs+=(
      --prefix PATH : "${lib.makeBinPath [ nodejs ]}"
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$GST_PLUGIN_SYSTEM_PATH_1_0"
      --prefix GIO_EXTRA_MODULES : "${glib-networking.out}/lib/gio/modules"
    )

    install -Dm644 ../LICENSE $out/share/licenses/kmusic/LICENSE
    install -Dm644 ../vendor/nextkdeAppDemo/LICENSE $out/share/licenses/kmusic/Kos.Ui-LICENSE
  '';

  meta = {
    description = "Qt Quick music player for NextKde with local and online sources";
    homepage = "https://github.com/NextKde/KMusic";
    # The main application and Kos.Ui are GPLv3; the bundled NetEase helper
    # carries its own AGPLv3 license and provenance notice in providers/.
    license = [
      lib.licenses.gpl3Only
      lib.licenses.agpl3Only
    ];
    platforms = lib.platforms.linux;
    mainProgram = "kmusic";
  };
}
