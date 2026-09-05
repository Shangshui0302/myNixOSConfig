{ pkgs }:
let
  pname = "animeko";
  version = "6.1.0";
  src = pkgs.fetchurl {
    url = "https://github.com/open-ani/animeko/releases/download/v${version}/ani-${version}-linux-x86_64.appimage";
    hash = "sha256-q+6rAdr0oIqxzXxNnGmZsXQaV32TrX4u8ouA6hIpaqc=";
  };
  iconSrc = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/open-ani/animeko/v${version}/app/desktop/icons/a_1024x1024_rounded.ico";
    hash = "sha256-VVce+BK2M2j6r3ag/7chcP5YLYKZtY+H0kIgz0mBrkQ=";
  };
  icon =
    pkgs.runCommand "${pname}-icon"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        magick "${iconSrc}[6]" "png:$out"
      '';
  app = pkgs.appimageTools.wrapType2 {
    inherit pname version src;
  };
in
pkgs.stdenvNoCC.mkDerivation {
  inherit pname version src;
  dontUnpack = true;

  nativeBuildInputs = [
    pkgs.copyDesktopItems
    pkgs.makeWrapper
  ];

  desktopItems = [
    (pkgs.makeDesktopItem {
      name = pname;
      desktopName = "Animeko";
      comment = "集找番、追番、看番的一站式弹幕追番平台";
      exec = pname;
      icon = pname;
      categories = [
        "AudioVideo"
        "Player"
        "Video"
      ];
    })
  ];

  installPhase = ''
    runHook preInstall
    makeWrapper ${app}/bin/${pname} "$out/bin/${pname}" \
      --prefix JAVA_TOOL_OPTIONS " " "-Dsun.java2d.uiScale=2.0"
    install -Dm644 ${icon} "$out/share/icons/hicolor/256x256/apps/${pname}.png"
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "One-stop platform for finding, following and watching anime";
    homepage = "https://github.com/open-ani/animeko";
    license = licenses.agpl3Plus;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
