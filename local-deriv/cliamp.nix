{ pkgs }:

let
  pname = "cliamp";
  version = "2.0.1";
  src = pkgs.fetchurl {
    url = "https://github.com/bjarneo/cliamp/releases/download/v${version}/cliamp-linux-amd64";
    hash = "sha256-qWwsaDvFxY7u5JbjzIkRPaRgUadP57IhTH9AknWLhSw=";
  };
in
pkgs.stdenv.mkDerivation {
  inherit pname version src;

  dontUnpack = true;
  dontStrip = true;

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
    pkgs.makeWrapper
  ];
  buildInputs = [ pkgs.alsa-lib ];

  installPhase = ''
    install -Dm755 "$src" "$out/libexec/${pname}"
    makeWrapper "$out/libexec/${pname}" "$out/bin/${pname}" \
      --prefix PATH : "${
        pkgs.lib.makeBinPath [
          pkgs.ffmpeg-headless
          pkgs.yt-dlp
        ]
      }"
  '';

  # Generate completions only after the release binary can execute in the build
  # environment. autoPatchelfHook's own postFixup hook runs after this hook, so
  # invoke it once here and let the normal hook repeat the harmless fixup.
  postFixup = ''
    autoPatchelf -- "$out"
    install -d "$out/share/fish/vendor_completions.d" \
      "$out/share/bash-completion/completions"
    "$out/bin/${pname}" completion fish \
      > "$out/share/fish/vendor_completions.d/${pname}.fish"
    "$out/bin/${pname}" completion bash \
      > "$out/share/bash-completion/completions/${pname}"
  '';

  meta = with pkgs.lib; {
    description = "Retro terminal music player inspired by Winamp";
    homepage = "https://github.com/bjarneo/cliamp";
    license = licenses.mit;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
