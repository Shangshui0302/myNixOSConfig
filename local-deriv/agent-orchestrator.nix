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
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  dbus-glib,
  expat,
  gh,
  git,
  glib,
  gtk3,
  imagemagick,
  libdbusmenu-gtk3,
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
  nodejs_22,
  openssh,
  pango,
  python3,
  systemd,
}:

let
  pname = "agent-orchestrator";
  version = "0.14.5";
  src = fetchurl {
    url = "https://github.com/OrchestratorInc/agent-orchestrator/releases/download/v${version}/${pname}-linux-x64.AppImage";
    hash = "sha256-gCLkdiwgRWW5PtUJEMXzShhMcoDj4B2MxaPuC9n67nI=";
  };
  extracted = appimageTools.extract { inherit pname version src; };
  licenseFile = fetchurl {
    url = "https://raw.githubusercontent.com/OrchestratorInc/agent-orchestrator/v${version}/LICENSE";
    hash = "sha256-GiIZcit+9YNkBl6Qc6LLKDGJHrFHp4V0KjFDHJzdrR0=";
  };
  desktopItem = makeDesktopItem {
    name = pname;
    desktopName = "Agent Orchestrator";
    comment = "Plan, run, and supervise coding agents";
    exec = "${pname} %U";
    icon = pname;
    terminal = false;
    categories = [ "Development" ];
    mimeTypes = [ "x-scheme-handler/ao-app" ];
    startupWMClass = pname;
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

  # Direct ELF NEEDED entries of the bundled Electron, ACP Node, tmux,
  # agent-browser, better-sqlite3 and AppImage's compatibility libraries.
  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    dbus-glib
    expat
    glib
    gtk3
    libdbusmenu-gtk3
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

  # Chromium keyring backend and ANGLE's observed libGL.so.1 dlopen target.
  runtimeDependencies = [
    libsecret
    libGL
  ];
  dontWrapGApps = true;
  dontStrip = true;
  # Run explicitly before addDriverRunpath; the automatic post-fixup hook would
  # otherwise recompute RPATH and remove that final driver search directory.
  dontAutoPatchelf = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/${pname}" "$out/bin" "$out/share/applications"
    cp -a . "$out/lib/${pname}/"
    ${python3}/bin/python ${./agent-orchestrator/patch-asar.py} \
      "$out/lib/${pname}/resources/app.asar"
    # The bundled Node 22.23.2 crashes after patchelf rewrites its ELF layout.
    # ACP ships only JS (no .node addons), so use the locked Nixpkgs Node 22;
    # keep Electron and its ABI-specific better-sqlite3 modules unchanged.
    rm "$out/lib/${pname}/resources/acp-runtime/node/bin/node"
    ln -s ${lib.getExe nodejs_22} "$out/lib/${pname}/resources/acp-runtime/node/bin/node"
    cp -a usr/share/icons "$out/share/"
    # The AppImage only ships 1024x1024, absent from the hicolor directory
    # index and Noctalia's fallback paths. Install indexed sizes as well.
    for size in 16 32 48 64 128 256 512; do
      mkdir -p "$out/share/icons/hicolor/''${size}x''${size}/apps"
      magick "$out/share/icons/hicolor/1024x1024/apps/${pname}.png" \
        -resize "''${size}x''${size}" \
        "$out/share/icons/hicolor/''${size}x''${size}/apps/${pname}.png"
    done
    # AppImage's top-level LICENSE belongs to Electron; include AO's license too.
    install -Dm644 ${licenseFile} "$out/share/doc/${pname}/LICENSE"
    install -m644 ${desktopItem}/share/applications/${pname}.desktop \
      "$out/share/applications/${pname}.desktop"
    substituteInPlace "$out/share/applications/${pname}.desktop" \
      --replace-fail 'Exec=${pname} %U' "Exec=$out/bin/${pname} %U"

    # Keep the native CLI usable from host and Distrobox without an FHS/PID
    # namespace. Preserve Electron's own ABI and all packaged resources.
    makeWrapper "$out/lib/${pname}/resources/daemon/ao" "$out/bin/ao" \
      --prefix PATH : ${
        lib.makeBinPath [
          git
          gh
          openssh
        ]
      } \
      --set-default AO_TMUX_BINARY "$out/lib/${pname}/resources/tmux/bin/tmux"
    runHook postInstall
  '';

  postFixup = ''
    autoPatchelf -- "$out"
    addDriverRunpath "$out/lib/${pname}/${pname}"
    # The extracted executable is not an AppImage: leaving APPIMAGE unset also
    # makes electron-updater's AppImageUpdater inactive on this Nix install.
    # Route the default daemon through the CLI wrapper after AO restores its
    # login-shell environment, so Git/SSH and gh auth are in its runtime PATH.
    makeWrapper "$out/lib/${pname}/${pname}" "$out/bin/${pname}" \
      "''${gappsWrapperArgs[@]}" \
      --set-default AO_DAEMON_COMMAND "$out/bin/ao daemon" \
      --unset APPIMAGE \
      --unset APPDIR
  '';

  meta = {
    description = "Desktop workspace for planning, running, and supervising coding agents";
    homepage = "https://github.com/OrchestratorInc/agent-orchestrator";
    changelog = "https://github.com/OrchestratorInc/agent-orchestrator/releases/tag/v${version}";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
