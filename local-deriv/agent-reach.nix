{
  lib,
  fetchFromGitHub,
  python3Packages,
  yt-dlp,
  deno,
}:

python3Packages.buildPythonApplication {
  pname = "agent-reach";
  version = "1.5.0-unstable-2026-10-07";
  pyproject = true;

  # The release tag predates the read-only install/doctor and credential fixes.
  src = fetchFromGitHub {
    owner = "Panniantong";
    repo = "Agent-Reach";
    rev = "94f06c1969dfc1834001269d79d3ad0972d9dee6";
    hash = "sha256-P/odFlAc9NcNsmoQc3L2DQpH3oTh9a2NsJtWzoMTYRk=";
  };

  build-system = [ python3Packages.hatchling ];

  dependencies = with python3Packages; [
    requests
    feedparser
    python-dotenv
    loguru
    pyyaml
    rich
    yt-dlp
  ];

  # Nixpkgs yt-dlp already uses this Deno by store path. Expose it to doctor,
  # which otherwise only checks the caller's PATH and reports a false warning.
  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath [
      yt-dlp
      deno
    ])
  ];

  pythonImportsCheck = [
    "agent_reach"
    "agent_reach.cli"
  ];

  meta = {
    description = "Health checks and tool routing for AI agent internet access";
    homepage = "https://github.com/Panniantong/Agent-Reach";
    license = lib.licenses.mit;
    mainProgram = "agent-reach";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
