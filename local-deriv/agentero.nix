{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  gtk3,
  webkitgtk_4_1,
  glib,
  glib-networking,
  libsoup_3,
  cairo,
  gdk-pixbuf,
  dbus,
  nodejs,
  git,
  openssh,
  xdg-utils,
}:

let
  # Annotated v0.15.4 tag's release commit (Release workflow 42666418293).
  rev = "fdacc2bc9da8a4e5569cf986acf2ef09e62d396b";
  notices =
    map
      (
        notice:
        fetchurl {
          url = "https://raw.githubusercontent.com/poco-ai/Agentero/${rev}/${notice.path}";
          name = baseNameOf notice.path;
          sha256 = notice.hash;
        }
      )
      [
        {
          path = "LICENSE";
          hash = "f2b7f0cc6fb11f63654ac171d46640de6a8f63407a1a9fa77181a5c43a841fcf";
        }
        {
          path = "THIRD_PARTY.md";
          hash = "7e0f98ed9c5029d0de423e082dcdce3f2c921870f76b51272a4ce9095a3b0de4";
        }
        {
          path = ".github/THIRD_PARTY_NOTICES.md";
          hash = "c9f9e436b1accc7e659df6452d7cca7bde1618cbf132b663230d0dbd70ea44d2";
        }
      ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "agentero";
  version = "0.15.4";

  # Upstream's Linux bundle includes the plugin host, ACP adapters and PDFium.
  src = fetchurl {
    url = "https://github.com/poco-ai/Agentero/releases/download/v${finalAttrs.version}/Agentero_${finalAttrs.version}_amd64.deb";
    sha256 = "ce88db7da31d7007d84fb2ee41420ca01e727da5a3f76a660cdfb1b95243f382";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
  ];
  buildInputs = [
    gtk3
    webkitgtk_4_1
    glib
    glib-networking
    libsoup_3
    cairo
    gdk-pixbuf
    dbus
    stdenv.cc.cc.lib
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r usr/. "$out/"
    substituteInPlace "$out/share/applications/Agentero.desktop" \
      --replace-fail 'Comment=A Tauri App' 'Comment=AI workspace for documents and agents' \
      --replace-fail 'Exec=agentero' "Exec=$out/bin/agentero"
    mkdir -p "$out/share/licenses/agentero"
    for notice in ${lib.escapeShellArgs notices}; do
      name="$(stripHash "$notice")"
      install -m444 "$notice" "$out/share/licenses/agentero/$name"
    done
    runHook postInstall
  '';

  preFixup = ''
    # Keep optional agent/remote-vault/open-link tools available without replacing
    # the user's PATH (in particular their own Claude/Codex executables).
    gappsWrapperArgs+=(
      --prefix PATH : ${
        lib.makeBinPath [
          nodejs
          git
          openssh
          xdg-utils
        ]
      }
      --set PDFIUM_LIB_PATH "$out/lib/Agentero/pdfium"
      --set AGENTERO_PLUGIN_WORKER "$out/bin/agentero-plugin-host"
    )
  '';

  meta = {
    description = "AI workspace for documents and agents";
    homepage = "https://github.com/poco-ai/Agentero";
    changelog = "https://github.com/poco-ai/Agentero/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "agentero";
  };
})
