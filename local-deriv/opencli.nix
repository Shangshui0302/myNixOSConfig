{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  importNpmLock,
}:

buildNpmPackage (finalAttrs: {
  pname = "opencli";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "jackwener";
    repo = "opencli";
    rev = "74fe1dc11c26d44b2a01102fd341aa55ae407774"; # v2.0.0
    hash = "sha256-B5rJpMI/4qtcAehD/XgQeGCC/JGIbBmKmuX+Fg+JVms=";
  };

  # Fetch each locked tarball by its upstream integrity hash, allowing Nix to
  # cache and retry downloads independently.
  npmDeps = importNpmLock { npmRoot = finalAttrs.src; };
  npmConfigHook = importNpmLock.npmConfigHook;

  # Upstream's install hooks migrate ~/.opencli and install completions.
  # Keep those out of the build, while retaining build-script lifecycle hooks
  # (prebuild-manifest compiles TypeScript before generating the adapter index).
  npmRebuildFlags = [ "--ignore-scripts" ];
  npmPackFlags = [ "--ignore-scripts" ];
  npmPruneFlags = [ "--ignore-scripts" ];

  meta = {
    description = "Expose websites as CLI commands using built-in adapters";
    homepage = "https://github.com/jackwener/opencli";
    license = lib.licenses.asl20;
    mainProgram = "opencli";
  };
})
