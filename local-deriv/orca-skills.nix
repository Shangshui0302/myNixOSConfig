{
  lib,
  fetchurl,
  linkFarm,
  communityOrca,
}:

let
  revision = "b2879bd5aaac5d27c101ccf4171faa25d9f0bb1e";
  hashes = {
    orca-cli = "sha256-qnb4ZQUBAJbo6p7doXBaeKrnr0XlRIXz/gRgZkwdnko=";
    orchestration = "sha256-zRs2S/NXgbrQa/dasXZq+o1s7GnLIGBSlpHYmHGiCYo=";
  };
in
assert lib.assertMsg (
  communityOrca.version == "1.4.230"
) "Update the pinned Orca skill stubs together with the community Orca version";
linkFarm "orca-skills-${communityOrca.version}" (
  lib.mapAttrsToList (name: hash: {
    name = "${name}/SKILL.md";
    path = fetchurl {
      url = "https://raw.githubusercontent.com/stablyai/orca/${revision}/skills/${name}/SKILL.md";
      inherit hash;
    };
  }) hashes
)
