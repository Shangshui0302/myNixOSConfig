{ pkgs }:
let
  pname = "animeko";
  version = "5.6.0";
  src = pkgs.fetchurl {
    url = "https://github.com/open-ani/animeko/releases/download/v5.6.0/ani-5.6.0-linux-x86_64.appimage";
    hash = "sha256-GN5i5RnOHl4sDE9Tr4EmkcBOwhvNlbaB2mUTiy7RIdk=";
  };
  iconSrc = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/open-ani/animeko/v${version}/app/desktop/icons/a_1024x1024_rounded.ico";
    hash = "sha256-VVce+BK2M2j6r3ag/7chcP5YLYKZtY+H0kIgz0mBrkQ=";
  };
  icon = pkgs.runCommand "${pname}-icon" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
    magick "${iconSrc}[6]" "png:$out"
  '';
  app = pkgs.appimageTools.wrapType2 {
    inherit pname version src;
    extraPkgs = pkgs: with pkgs; [ ];
  };
in
(pkgs.writeShellScriptBin pname ''
  export JAVA_TOOL_OPTIONS="-Dsun.java2d.uiScale=1.5''${JAVA_TOOL_OPTIONS:+ $JAVA_TOOL_OPTIONS}"
  exec ${app}/bin/${pname} "$@"
'').overrideAttrs (_: {
  passthru = { inherit icon; };
})
