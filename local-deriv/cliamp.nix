{ pkgs }:

pkgs.buildGoModule (finalAttrs: {
  pname = "cliamp";
  version = "2.0.1";

  src = pkgs.fetchFromGitHub {
    owner = "bjarneo";
    repo = "cliamp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-r7MrrcVt+/f+iPozn9jaczJmpPv431wAoW8LvHKBtB8=";
  };

  vendorHash = "sha256-rtwUWbft5XGEbuBCn0OMCn4TS5Ul+UXJNIqNOzXfU+M=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${finalAttrs.version}"
  ];

  nativeBuildInputs = [
    pkgs.pkg-config
    pkgs.makeWrapper
  ];

  buildInputs = [
    pkgs.alsa-lib
    pkgs.flac
    pkgs.libogg
    pkgs.libvorbis
    pkgs.mpg123
  ];

  postInstall = ''
    wrapProgram "$out/bin/${finalAttrs.pname}" \
      --prefix PATH : "${
        pkgs.lib.makeBinPath [
          pkgs.ffmpeg-headless
          pkgs.yt-dlp
        ]
      }"
    install -d "$out/share/fish/vendor_completions.d" \
      "$out/share/bash-completion/completions"
    "$out/bin/${finalAttrs.pname}" completion fish \
      > "$out/share/fish/vendor_completions.d/${finalAttrs.pname}.fish"
    "$out/bin/${finalAttrs.pname}" completion bash \
      > "$out/share/bash-completion/completions/${finalAttrs.pname}"
  '';

  meta = with pkgs.lib; {
    description = "Retro terminal music player inspired by Winamp";
    homepage = "https://github.com/bjarneo/cliamp";
    license = licenses.mit;
    mainProgram = finalAttrs.pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
})
