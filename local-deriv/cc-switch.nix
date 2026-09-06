{ pkgs }:

pkgs.cc-switch.overrideAttrs (old: rec {
  version = "3.20.1";

  src = pkgs.fetchFromGitHub {
    owner = "farion1231";
    repo = "cc-switch";
    tag = "v${version}";
    hash = "sha256-JBD9zp2vPYSS39X3NLBEpFPuvDkESv66nHzVU8pJ4i0=";
  };

  pnpmDeps = pkgs.fetchPnpmDeps {
    pname = old.pname;
    inherit version src;
    pnpm = pkgs.pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-uqY6/WSVsuvfcJsbWMYenaxLp9gDguiMAyb/mepv028=";
  };

  cargoHash = null;
  cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
    inherit src;
    cargoRoot = "src-tauri";
    hash = "sha256-nLDi1jEWEhVm4h/1H3KRE5ClAfKzxaAgGrxA2/lshJ0=";
  };

  # ponytail: sandbox-incompatible FHS tests stay disabled; re-enable after
  # upstream switches those tests to Nix paths or test doubles.
  doCheck = false;
})
