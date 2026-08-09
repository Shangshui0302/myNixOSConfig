{ pkgs }:
pkgs.stdenv.mkDerivation rec {
  pname = "rtk";
  version = "0.45.0";

  # rtk-ai/rtk — Rust Token Killer: token-optimized CLI proxy.
  # nixpkgs 里的 `rtk` 是 C++ 数学库 (exprtk)，撞名，所以用 musl 静态二进制自打包。
  src = pkgs.fetchurl {
    url = "https://github.com/rtk-ai/rtk/releases/download/v${version}/rtk-x86_64-unknown-linux-musl.tar.gz";
    sha256 = "sha256-xMA2+/GB/FXvMpeGyMF+DUJ5crBTuCWUTZaKaq/vG6Q=";
  };

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 rtk $out/bin/rtk
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Rust Token Killer — CLI proxy reducing LLM token consumption 60-90% on dev commands";
    homepage = "https://github.com/rtk-ai/rtk";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
  };
}
