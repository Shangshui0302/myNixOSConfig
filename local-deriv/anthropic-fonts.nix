{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "anthropic-fonts";
  version = "0-unstable-2026-05-19";

  src = pkgs.fetchFromGitHub {
    owner = "zihaveaDream";
    repo = "obsidian-claude-minimal";
    rev = "c64020c87610cebf3188febbfd7156a3c51b9687";
    hash = "sha256-9REAK8ii9bLb4T40e8ivPZigOwOokibn6xOUZDpxQ/Y=";
  };

  installPhase = ''
    runHook preInstall
    install -Dm644 fonts/anthropic/*.ttf -t "$out/share/fonts/truetype"
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Anthropic web fonts used by the Claude for Minimal Obsidian theme";
    homepage = "https://github.com/zihaveaDream/obsidian-claude-minimal";
    # The upstream repository does not publish a license; keep this opt-in and
    # do not imply that the fonts are redistributable under a free license.
    license = licenses.unfree;
    platforms = platforms.linux;
  };
}
