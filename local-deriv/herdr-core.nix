{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "herdr-core";
  version = "0.1.16";
  src = fetchurl {
    url = "https://releases.herdr.dev/core/${finalAttrs.version}/herdr-core-linux-x86_64.tar.gz";
    hash = "sha256-WNaGEXbcb+kFtYiA1b/weplZvmE6mOXWa0WDsEts+kU=";
  };
  sourceRoot = ".";
  dontBuild = true;
  # Upstream ships a static PIE; it needs no ELF interpreter patching.
  installPhase = ''
    runHook preInstall
    install -Dm755 herdr-core $out/bin/herdr-core
    ln -s herdr-core $out/bin/hc
    install -Dm644 LICENSE $out/share/licenses/herdr-core/LICENSE
    install -Dm644 THIRD-PARTY-NOTICES $out/share/licenses/herdr-core/THIRD-PARTY-NOTICES
    runHook postInstall
  '';
  meta = {
    description = "Persistent terminal runtime for Herdr";
    homepage = "https://github.com/herdrdev/herdr-core";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "herdr-core";
  };
})
