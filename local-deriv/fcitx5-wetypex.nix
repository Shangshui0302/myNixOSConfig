{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  kdePackages,
  fcitx5,
  libime,
  boost,
  json_c,
  fontconfig,
  wayland,
  curl,
  llvmPackages,
  python3,
  bash,
  coreutils,
  util-linux,
  bubblewrap,
  cacert,
  pipewire,
  ffmpeg,
  wl-clipboard,
  desktop-file-utils,
  writeText,
  # Allow upstream's controls to change the shared Fcitx5 theme and font.
  enableWeTypeTheme ? false,
  enableAI ? true,
  enableVoice ? true,
  enableLayerShell ? true,
  defaultSettings ? { },
}:

assert lib.assertMsg (builtins.isAttrs defaultSettings)
  "WeTypeX defaultSettings must be an attribute set";

let
  defaultSettingsFile = writeText "fcitx5-wetypex-default-settings.json" (
    builtins.toJSON defaultSettings
  );
  # WeTypeX's transport bridge requires WS/WSS; nixpkgs disables them by default.
  transportCurl = curl.override { websocketSupport = true; };
  python = python3.withPackages (ps: [
    ps.fonttools
    ps.pillow
  ]);
  featuresFile = writeText "fcitx5-wetypex-features.json" (
    builtins.toJSON {
      inherit
        enableAI
        enableVoice
        enableLayerShell
        enableWeTypeTheme
        ;
    }
  );
  runtimePath = lib.makeBinPath (
    [
      coreutils
      util-linux
      bubblewrap
      fontconfig
      wl-clipboard
      python
    ]
    ++ lib.optionals enableVoice [
      pipewire
      ffmpeg
    ]
  );
  # Match the revision used by upstream's CMake and release build.
  kqueueSource = fetchFromGitHub {
    owner = "mheily";
    repo = "libkqueue";
    rev = "46a3e130f88b0b0742575dcb01d77e336538024b";
    hash = "sha256-bUtjzGxQHJkd9SxlXpA8xJ4hT0IeMHrlcfRLMTdT59k=";
  };
in
stdenv.mkDerivation {
  pname = "fcitx5-wetypex";
  version = "2.2.3.657-13";

  src = fetchFromGitHub {
    owner = "panxuc";
    repo = "fcitx5-wetypex";
    # v2.2.3.657-13, released 2026-10-25.
    rev = "291193a26938e0e8858d72b737066f37eb7a5f94";
    hash = "sha256-s9Y98Ni8hnmNwl1F1bQJUHrr9gFMUYtHnJBsGaS46f4=";
  };

  patches = [
    ./wetypex/nixos-runtime.patch
    ./wetypex/feature-options.patch
  ]
  # ClassicUI is shared with Rime; keep desktop ownership unless opted in.
  ++ lib.optional (!enableWeTypeTheme) ./wetypex/preserve-desktop-theme.patch;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    kdePackages.extra-cmake-modules
    kdePackages.wrapQtAppsHook
    python
  ];

  buildInputs = [
    fcitx5
    libime
    boost
    json_c
    fontconfig
    wayland
    transportCurl
    llvmPackages.libcxx
    kdePackages.fcitx5-qt
    kdePackages.qtbase
    kdePackages.qtsvg
    kdePackages.qtwayland
  ]
  ++ lib.optional enableAI kdePackages.qtwebengine
  ++ lib.optional enableLayerShell kdePackages.layer-shell-qt;

  postPatch = ''
    while IFS= read -r -d "" file; do
      substituteInPlace "$file" \
        --replace-quiet '@NIX_RUNTIME_PATH@' '${runtimePath}' \
        --replace-quiet '@NIX_PYTHON@' '${python}/bin/python3' \
        --replace-quiet '@NIX_BASH@' '${bash}/bin/bash' \
        --replace-quiet '@NIX_CA_BUNDLE@' '${cacert}/etc/ssl/certs/ca-bundle.crt' \
        --replace-quiet '@NIX_LIBCXX@' '${lib.getLib llvmPackages.libcxx}/lib/libc++.so.1' \
        --replace-quiet '@NIX_LIBCXXABI@' '${lib.getLib llvmPackages.libcxx}/lib/libc++abi.so.1' \
        --replace-quiet '@NIX_OUT@' "$out"
      substituteInPlace "$file" \
        --replace-quiet '@NIX_DEFAULT_SETTINGS@' "$out/share/fcitx5-wetypex/default-settings.json" \
        --replace-quiet '@NIX_VOICE_ENABLED@' '${if enableVoice then "1" else "0"}'
    done < <(grep -rlZ '@NIX_' scripts src tools)
    patchShebangs scripts tools
  '';

  cmakeFlags = [
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    "-DFETCHCONTENT_SOURCE_DIR_KQUEUE=${kqueueSource}"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    "-DWETYPE_QT_VERSION=6"
    "-DWETYPE_LAYER_SHELL=${if enableLayerShell then "ON" else "OFF"}"
    "-DWETYPE_ENABLE_AI=${lib.boolToString enableAI}"
    "-DWETYPE_ENABLE_VOICE=${lib.boolToString enableVoice}"
    # Use the locked curl with WS/WSS enabled, without a configure-time fetch.
    "-DWETYPE_BUNDLED_CURL=OFF"
    "-DWETYPE_CLANGXX=${llvmPackages.libcxxStdenv.cc}/bin/clang++"
  ];

  postInstall = ''
    install -Dm444 ${defaultSettingsFile} "$out/share/fcitx5-wetypex/default-settings.json"
    install -Dm444 ${featuresFile} "$out/share/fcitx5-wetypex/features.json"
  '';

  # The upstream project has no CTest suite; retain its release script checks.
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    for script in ../scripts/*.sh.in; do
      case "$script" in
        *-syncd.sh.in|*-update.sh.in|*-sync.sh.in) continue ;;
      esac
      ${bash}/bin/bash -n "$script"
    done
    export PYTHONPYCACHEPREFIX="$TMPDIR/wetypex-pycache"
    ${python}/bin/python3 -m py_compile \
      ../scripts/*.py ../tools/*.py \
      fcitx5-wetypex-syncd fcitx5-wetypex-update fcitx5-wetypex-sync
    ${python}/bin/python3 ../tests/test_init_settings.py
    runHook postCheck
  '';

  nativeInstallCheckInputs = [ desktop-file-utils ];
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    test -f "$out/lib/fcitx5/wetypex.so"
    test -f "$out/lib/fcitx5/qt6/libwetypexconfig.so"
    test -f "$out/share/fcitx5/inputmethod/wetypex.conf"
    desktop-file-validate "$out/share/applications/fcitx5-wetypex-settings.desktop"
    "$out/bin/fcitx5-wetypex-setup" --help >/dev/null
    "$out/bin/fcitx5-wetypex-init-settings" --help >/dev/null
    test -f "$out/share/fcitx5-wetypex/features.json"
    ${lib.optionalString (!enableAI) ''
      test ! -e "$out/bin/fcitx5-wetypex-ai"
      test ! -e "$out/bin/fcitx5-wetypex-ai-viewer"
    ''}
    ${lib.optionalString (!enableVoice) ''
      test ! -e "$out/bin/fcitx5-wetypex-voice"
      test ! -e "$out/share/fcitx5-wetypex/voice_stream.py"
      code=0
      "$out/bin/fcitx5-wetypex-account" voice-file /nonexistent > /dev/null 2>voice-disabled.txt || code=$?
      test "$code" -eq 78
      grep -q 'disabled by the package configuration' voice-disabled.txt
    ''}
    # This mode loads the host/transport libraries without a Tencent runtime,
    # user account, graphical session, or network request.
    "$out/bin/fcitx5-wetypex-account" network-info > network-info.json
    ${python}/bin/python3 -c \
      'import json; d=json.load(open("network-info.json")); assert all(d[k] for k in ("utf8_json", "ws", "wss")), d'
    runHook postInstallCheck
  '';

  passthru = {
    inherit
      enableWeTypeTheme
      enableAI
      enableVoice
      enableLayerShell
      defaultSettings
      ;
  };

  meta = {
    description = "Fcitx5 compatibility layer for the WeType macOS input engine";
    homepage = "https://github.com/panxuc/fcitx5-wetypex";
    license = with lib.licenses; [
      mit
      isc
      bsd2
    ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "fcitx5-wetypex-settings";
  };
}
