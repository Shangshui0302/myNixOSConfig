{
  lib,
  appimageTools,
  fetchurl,
  kiro-cli-unwrapped,
  stdenv,
  wl-clipboard,
}:

let
  pname = "kirocrew";
  version = "0.11.1";
  src = fetchurl {
    url = "https://github.com/kirodotdev/KiroCrew/releases/download/v${version}/KiroCrew-${version}-x86_64.AppImage";
    hash = "sha256-xRkiXoo311+QTMEnBgpDfLC+xZtdLjXlVR5K2l+dFG8=";
  };
  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # Crew pins an absolute CLI path and intentionally ignores inherited PATH
  # when spawning agents. Use the unwrapped CLI inside this existing FHS.
  extraPkgs = _: [
    kiro-cli-unwrapped
    stdenv.cc.cc.lib
    wl-clipboard
  ];
  profile = ''
    export KIROCREW_KIRO_BIN="''${KIROCREW_KIRO_BIN:-${lib.getExe kiro-cli-unwrapped}}"
  '';

  extraInstallCommands = ''
    install -Dm644 ${contents}/kirocrew-desktop.desktop $out/share/applications/kirocrew.desktop
    substituteInPlace $out/share/applications/kirocrew.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=kirocrew'
    install -Dm644 ${contents}/kirocrew-desktop.png $out/share/icons/hicolor/512x512/apps/kirocrew-desktop.png
  '';

  meta = {
    description = "Persistent AI agent workspace";
    homepage = "https://github.com/kirodotdev/KiroCrew";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "kirocrew";
  };
}
