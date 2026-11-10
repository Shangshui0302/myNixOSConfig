{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  patchelf,
}:

# DSH's node-addon-require-builtin probes private Node/V8 machine code. The
# nixpkgs Node 24 build fails its getter probe, so use the official binary.
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "dsh-x-node";
  version = "24.21.0";

  src = fetchurl {
    url = "https://nodejs.org/dist/v${finalAttrs.version}/node-v${finalAttrs.version}-linux-x64.tar.xz";
    hash = "sha256-/Y5Z1aURUQ9qKYr7VI8Yx9KxvkBNi0on2U++SfVsstY=";
  };

  nativeBuildInputs = [
    makeWrapper
    patchelf
  ];

  # Preserve the official runtime's symbols for the addon's private API probe.
  dontStrip = true;
  # autoPatchelf's RUNPATH rewrite breaks this release's non-PIE ELF layout.
  # Only change PT_INTERP; supply the two C++ runtime libraries in the wrapper.
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 bin/node "$out/libexec/node"
    mkdir -p "$out/lib/node_modules"
    cp -a lib/node_modules/npm "$out/lib/node_modules/"
    install -Dm644 LICENSE "$out/share/licenses/${finalAttrs.pname}/LICENSE"

    runHook postInstall
  '';

  postFixup = ''
    patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} "$out/libexec/node"
    makeWrapper "$out/libexec/node" "$out/bin/node" \
      --prefix PATH : "$out/bin" \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          stdenv.cc.cc.lib
          stdenv.cc.cc.libgcc
        ]
      }

    # The generated dsh entrypoint also runs this wrapper outside DSH-X.
    # Keep npm/npx and their lifecycle scripts on the same Node runtime.
    makeWrapper "$out/bin/node" "$out/bin/npm" \
      --add-flags "$out/lib/node_modules/npm/bin/npm-cli.js"
    makeWrapper "$out/bin/node" "$out/bin/npx" \
      --add-flags "$out/lib/node_modules/npm/bin/npx-cli.js"
  '';

  # Catch loader failures in the packaged executable, after interpreter fixup.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/node" --version
    "$out/bin/npm" --version
    "$out/bin/npx" --version
    runHook postInstallCheck
  '';

  meta = {
    description = "Official Node.js runtime for DSH-X native module compatibility";
    homepage = "https://nodejs.org/";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "node";
  };
})
