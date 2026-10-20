{
  lib,
  pkgs,
  inputs,
  ...
}:

let
  communityOrca = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.orca;
  orca = pkgs.callPackage ../../local-deriv/orca.nix { inherit communityOrca; };
  skills = pkgs.callPackage ../../local-deriv/orca-skills.nix { inherit communityOrca; };
  # Codex's shared root, both documented agy roots, and DSH's shared user root.
  # Each file has one store source; existing unrelated skills stay untouched.
  roots = [
    ".agents/skills"
    ".gemini/config/skills"
    ".gemini/antigravity-cli/skills"
    ".dsh/skills"
  ];
in
{
  home.packages = [ orca ];
  home.sessionVariables.ORCA_CLI_COMMAND = "${orca}/bin/orca-ide-cli";
  home.file = lib.listToAttrs (
    lib.concatMap (
      root:
      map
        (name: {
          name = "${root}/${name}";
          value.source = "${skills}/${name}";
        })
        [
          "orca-cli"
          "orchestration"
        ]
    ) roots
  );
}
