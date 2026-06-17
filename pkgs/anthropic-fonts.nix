{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "anthropic-fonts";
  src = pkgs.fetchFromGitHub {
    owner = "zihaveaDream";
    repo = "obsidian-claude-minimal";
    rev = "c64020c87610cebf3188febbfd7156a3c51b9687";
    sha256 = "sha256-9REAK8ii9bLb4T40e8ivPZigOwOokibn6xOUZDpxQ/Y=";
  };
  installPhase = ''
    mkdir -p $out/share/fonts/truetype
    cp $src/fonts/anthropic/*.ttf $out/share/fonts/truetype/
  '';
}
