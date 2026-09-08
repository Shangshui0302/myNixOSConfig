{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "modernz-mpv";
  version = "0.3.3";

  src = fetchFromGitHub {
    owner = "Samillion";
    repo = "ModernZ";
    tag = "v${finalAttrs.version}";
    hash = "sha256-cz6yb0jQiqmzRPo1YSsnPWLshGPzBeq39DhBv7tGJqs=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 modernz.lua "$out/share/mpv/scripts/modernz.lua"
    install -Dm644 modernz-icons.ttf "$out/share/fonts/modernz-icons.ttf"
    install -Dm644 extras/locale/modernz-locale.json \
      "$out/share/mpv/script-opts/modernz-locale.json"
    install -Dm644 LICENSE "$out/share/licenses/${finalAttrs.pname}/LICENSE"
    runHook postInstall
  '';

  meta = {
    description = "Sleek, customizable OSC interface for mpv";
    homepage = "https://github.com/Samillion/ModernZ";
    license = lib.licenses.lgpl21Only;
    platforms = lib.platforms.linux;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
  };
})
