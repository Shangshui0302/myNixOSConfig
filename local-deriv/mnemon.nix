{
  lib,
  stdenv,
  fetchurl,
  nodejs,
  autoPatchelfHook,
  makeWrapper,
}:

let
  version = "0.2.13";

  # The CLI is a thin launcher; the actual backend is a Go binary shipped as
  # a platform-specific npm package under the same name with a suffixed version.
  native = fetchurl {
    url = "https://registry.npmjs.org/@mnemon-dev/mnemon/-/mnemon-${version}-linux-x64.tgz";
    hash = "sha256-fjkQGn+Rwl7hc/SYaRF7qx2EFcz1sQmWBTpYguv6ycg=";
  };
in
stdenv.mkDerivation {
  pname = "mnemon";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@mnemon-dev/mnemon/-/mnemon-${version}.tgz";
    hash = "sha256-TPAF5CTBudIBJ+JKknBKs83S8n0+yhVlPm4SHEcySF0=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall

    pkg="$out/lib/node_modules/@mnemon-dev/mnemon"
    mkdir -p "$pkg/node_modules/@mnemon-dev/mnemon-linux-x64" "$out/bin"
    cp -a . "$pkg/"

    # Lay the platform package exactly where the CLI resolves it: the launcher
    # looks up @mnemon-dev/mnemon-linux-x64 next to its own package.
    tar -xzf ${native} -C "$pkg/node_modules/@mnemon-dev/mnemon-linux-x64" \
      --strip-components=1
    chmod +x "$pkg/node_modules/@mnemon-dev/mnemon-linux-x64/bin/mnemon"

    makeWrapper ${lib.getExe nodejs} "$out/bin/mnemon" \
      --add-flags "$pkg/bin/mnemon.js"

    runHook postInstall
  '';

  meta = {
    description = "Local memory backend for the Mnemon memory protocol";
    homepage = "https://www.npmjs.com/package/@mnemon-dev/mnemon";
    changelog = "https://www.npmjs.com/package/@mnemon-dev/mnemon?activeTab=versions";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "mnemon";
  };
}
