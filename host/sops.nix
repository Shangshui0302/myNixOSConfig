{ ... }:
{
  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    useSystemdActivation = true;
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
