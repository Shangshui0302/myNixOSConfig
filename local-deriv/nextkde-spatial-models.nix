{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  # Keep these bytes aligned with the pinned NextKDE ModelManager.h contracts.
  depth = fetchurl {
    url = "https://github.com/fabio-sim/Depth-Anything-ONNX/releases/download/v2.0.0/depth_anything_v2_vits_dynamic.onnx";
    hash = "sha256-RsTo7to6J/NHAYMbai7HdT17OHebIVrLVjNCRwPe7Y8=";
  };
  foreground = fetchurl {
    url = "https://github.com/danielgatis/rembg/releases/download/v0.0.0/isnet-general-use.onnx";
    hash = "sha256-YJIOmcRUZPK6V77irQjJGaUrv4UnOelpR/u0NYwNlko=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "nextkde-spatial-models";
  version = "1";
  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 ${depth} "$out/models/depth-anything-v2-small-vits.onnx"
    install -Dm644 ${foreground} "$out/models/isnet-general-use.onnx"
    runHook postInstall
  '';

  meta = {
    description = "Pinned depth and foreground models for NextKDE spatial wallpapers";
    homepage = "https://github.com/NextKde/NextKde";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
  };
}
