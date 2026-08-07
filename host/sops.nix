{ ... }:
{
  sops = {
    age.keyFile = "/persist/sops-age-key.txt";
    defaultSopsFile = ./secrets/secrets.yaml;
    secrets = {
      mihomo_env = {
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };
  };
}
