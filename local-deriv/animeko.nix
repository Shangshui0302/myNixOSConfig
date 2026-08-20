{ pkgs }:
let
  pname = "animeko";
  version = "5.6.0";
  src = pkgs.fetchurl {
    url = "https://github.com/open-ani/animeko/releases/download/v5.6.0/ani-5.6.0-linux-x86_64.appimage";
    hash = "sha256-GN5i5RnOHl4sDE9Tr4EmkcBOwhvNlbaB2mUTiy7RIdk=";
  };
  extracted = pkgs.appimageTools.extract { inherit pname version src; };
in
pkgs.appimageTools.wrapType2 {
  inherit pname version src;
  passthru = { inherit extracted; };
  extraPkgs = pkgs: with pkgs; [ ];
}
