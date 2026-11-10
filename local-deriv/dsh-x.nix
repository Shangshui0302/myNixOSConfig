{
  lib,
  stdenv,
  stdenvNoCC,
  callPackage,
  fetchurl,
  appimageTools,
  autoPatchelfHook,
  addDriverRunpath,
  makeDesktopItem,
  makeWrapper,
  wrapGAppsHook3,
  imagemagick,
  alsa-lib,
  at-spi2-core,
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
  pango,
  pnpm,
  systemd,
}:

let
  pname = "dsh-x";
  version = "0.1.26-rc.5";
  runtimeNode = callPackage ./dsh-x-node.nix { };

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
    at-spi2-core
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

  # Chromium keyring backend and ANGLE's libGL.so.1 dlopen target.
  runtimeDependencies = [
    libsecret
    libGL
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

    install -m644 ${./dsh-x/runtime-hooks.mjs} \
      "$out/lib/${pname}/resources/app/shell/nix-runtime.mjs"
    substituteInPlace "$out/lib/${pname}/resources/app/shell/main.mjs" \
      --replace-fail "import './env.mjs'" \
        "import './env.mjs'
    import { installCoreRuntimeHooks } from './nix-runtime.mjs'" \
      --replace-fail '  let core
      try {' \
        "  const runtimeHooks = installCoreRuntimeHooks(coreDir, '$out/bin/${pname}')
      let core
      try {" \
      --replace-fail '    // 用户目录里的核心坏到加载不了' \
        "    if (error?.code === 'DSH_NIX_RUNTIME_INCOMPATIBLE') {
          showStartupError('Nix 运行时适配失败', '请更新 DSH-X 的 Nix 包后重试。', error.message)
          return
        }
        // 用户目录里的核心坏到加载不了" \
      --replace-fail '  }
      server = core' \
        '  } finally {
        runtimeHooks.deregister()
      }
      server = core'

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
    # Some downloaded native addons have no library search path. Pass
    # libstdc++ through the inherited environment: the main executable's
    # RUNPATH does not cover those addons' transitive dependencies.
    #
    # Electron's system GLib conflicts with sharp's bundled GLib on Linux.
    # Use upstream's runtime override so the DSH core and its generated shims
    # run under ordinary Node, while the desktop shell stays in Electron.
    # https://sharp.pixelplumbing.com/install/#electron-and-linux
    makeWrapper "$out/lib/${pname}/DSH" "$out/bin/${pname}" \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${
        lib.makeBinPath [
          runtimeNode
          pnpm
        ]
      } \
      --set DSH_RUNTIME_NODE ${lib.getExe runtimeNode} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ stdenv.cc.cc.lib ]} \
      --unset APPIMAGE \
      --unset APPDIR
  '';

  passthru.runtimeNode = runtimeNode;

  doInstallCheck = true;
  nativeInstallCheckInputs = [ runtimeNode ];
  installCheckPhase = ''
    runHook preInstallCheck
    node --check "$out/lib/${pname}/resources/app/shell/main.mjs"
    DSH_NIX_RUNTIME_HOOKS="$out/lib/${pname}/resources/app/shell/nix-runtime.mjs" \
      DSH_NIX_SHELL_MAIN="$out/lib/${pname}/resources/app/shell/main.mjs" \
      node --test ${./dsh-x/runtime-hooks.test.mjs}
    runHook postInstallCheck
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
