{ pkgs }:
pkgs.stdenv.mkDerivation rec {
  pname = "officecli";
  version = "1.0.113";

  src = pkgs.fetchurl {
    url = "https://github.com/iOfficeAI/OfficeCLI/releases/download/v${version}/officecli-linux-x64";
    sha256 = "04bkh1wklvk0gcgqycnsmxsnfim4p01bhcgl9zj40qn7irgrzq7z";
  };

  dontUnpack = true;

  nativeBuildInputs = [ pkgs.autoPatchelfHook ];
  buildInputs = [ pkgs.stdenv.cc.cc.lib ];

  installPhase = ''
    install -Dm755 $src $out/bin/officecli
  '';

  meta = with pkgs.lib; {
    description = "Office suite CLI for AI agents — read, edit, and automate Word, Excel, PowerPoint files";
    homepage = "https://github.com/iOfficeAI/OfficeCLI";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "officecli";
  };
}
