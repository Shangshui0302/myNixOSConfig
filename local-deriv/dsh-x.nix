{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  appimageTools,
  autoPatchelfHook,
  addDriverRunpath,
  makeDesktopItem,
  makeWrapper,
  wrapGAppsHook3,
  imagemagick,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gnutar,
  gtk3,
  libgbm,
  libGL,
  libsecret,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  nspr,
  nss,
  nodejs_24,
  pango,
  pnpm,
  systemd,
}:

let
  pname = "dsh-x";
  version = "0.1.26-rc.5";

  src = fetchurl {
    url = "https://github.com/yyh-001/DSH-X/releases/download/v${version}/DSH-X-${version}-x86_64.AppImage";
    hash = "sha256-l/JbssUs4SslETUsArnrIb0x8Bjs0+XEepu5072UgWU=";
  };

  extracted = appimageTools.extract { inherit pname version src; };

  desktopItem = makeDesktopItem {
    name = pname;
    desktopName = "DSH-X";
    comment = "DeepSeek Harness 桌面启动器";
    exec = "${pname} %U";
    icon = pname;
    terminal = false;
    categories = [ "Development" ];
    startupWMClass = "DSH-X";
  };
in
stdenvNoCC.mkDerivation {
  inherit pname version;
  src = extracted;

  nativeBuildInputs = [
    autoPatchelfHook
    addDriverRunpath
    imagemagick
    makeWrapper
    wrapGAppsHook3
  ];

  # Direct ELF NEEDED entries of the bundled Electron 44.7.0 plus AppImage's
  # compatibility libraries.
  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libgbm
    libxkbcommon
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    systemd
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
  ];

  # Chromium keyring backend, ANGLE's libGL.so.1 dlopen target, and libstdc++.
  # The last one is not a NEEDED entry of the Electron binary itself (it links
  # only libgcc_s), but dsh's native addons — node-addon-require-builtin and
  # friends, loaded into the Electron process — do need libstdc++.so.6. Without
  # it in the RUNPATH those addons fail with "No usable native binding found".
  runtimeDependencies = [
    libsecret
    libGL
    stdenv.cc.cc.lib
  ];

  # The AppImage bundles a GTK2-era AppIndicator compatibility layer
  # (libappindicator/libindicator/libgconf/libdbusmenu). Electron 44 does not
  # link any of them; only the AppImage packer's leftovers do.
  autoPatchelfIgnoreMissingDeps = [
    "libdbusmenu-gtk.so.4"
    "libdbusmenu-glib.so.4"
    "libgtk-x11-2.0.so.0"
    "libdbus-glib-1.so.2"
  ];

  dontWrapGApps = true;
  dontStrip = true;
  # Run explicitly before addDriverRunpath; the automatic post-fixup hook would
  # otherwise recompute RPATH and drop that final driver search directory.
  dontAutoPatchelf = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/${pname}" "$out/bin" "$out/share/applications"
    cp -a . "$out/lib/${pname}/"
    cp -a usr/share/icons "$out/share/"

    # shell/core-fetch.mjs hardcodes /usr/bin/tar for the non-Windows branch;
    # NixOS has no /usr/bin, so the core download would fail to extract.
    substituteInPlace "$out/lib/${pname}/resources/app/shell/core-fetch.mjs" \
      --replace-fail "return '/usr/bin/tar'" "return '${lib.getExe' gnutar "tar"}'"

    # The AppImage only ships 512x512; install indexed sizes for the panel and
    # launcher, which do not read arbitrary hicolor sizes on every shell.
    for size in 16 32 48 64 128 256; do
      mkdir -p "$out/share/icons/hicolor/''${size}x''${size}/apps"
      magick "$out/share/icons/hicolor/512x512/apps/DSH.png" \
        -resize "''${size}x''${size}" \
        "$out/share/icons/hicolor/''${size}x''${size}/apps/${pname}.png"
    done
    install -m644 "$out/share/icons/hicolor/512x512/apps/DSH.png" \
      "$out/share/icons/hicolor/512x512/apps/${pname}.png"
    # The upstream name would otherwise linger as a second, unreferenced icon.
    rm "$out/share/icons/hicolor/512x512/apps/DSH.png"

    install -m644 ${desktopItem}/share/applications/${pname}.desktop \
      "$out/share/applications/${pname}.desktop"
    substituteInPlace "$out/share/applications/${pname}.desktop" \
      --replace-fail 'Exec=${pname} %U' "Exec=$out/bin/${pname} %U"

    runHook postInstall
  '';

  postFixup = ''
    autoPatchelf -- "$out"
    addDriverRunpath "$out/lib/${pname}/DSH"

    # The extracted executable is not an AppImage: leaving APPIMAGE unset keeps
    # electron-updater's AppImageUpdater inactive, so the shell never tries to
    # replace a store path. The core layer updates through npm into
    # ~/.config/DSH (or its XDG_CONFIG_HOME equivalent), which is writable.
    #
    # shell/env.mjs prepends its own node/ directory to PATH and falls back to
    # the user's PATH for node and pnpm; dsh plugin forwards to pnpm inside the
    # profile directory, so both must be reachable from the wrapper.
    #
    # LD_LIBRARY_PATH carries libstdc++ for the native addons. RUNPATH alone is
    # not enough: the .node files have no RUNPATH of their own, so dlopen
    # resolves their NEEDED entries against the main program's RUNPATH only for
    # that program's own direct dependencies — not transitively for a
    # dlopen'd object. Without this, loading node-addon-require-builtin fails
    # with "libstdc++.so.6: cannot open shared object file".
    makeWrapper "$out/lib/${pname}/DSH" "$out/bin/${pname}" \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${
        lib.makeBinPath [
          nodejs_24
          pnpm
        ]
      } \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ stdenv.cc.cc.lib ]} \
      --unset APPIMAGE \
      --unset APPDIR
  '';

  meta = {
    description = "Desktop launcher for DeepSeek Harness: launch entries, versions, plugins, MCP and skills";
    homepage = "https://github.com/yyh-001/DSH-X";
    changelog = "https://github.com/yyh-001/DSH-X/releases/tag/v${version}";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
