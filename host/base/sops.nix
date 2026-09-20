{ inputs, pkgs, ... }:
{
  sops = {
    # 临时兼容：只为 sops-install-secrets 替换旧 Go 构建器。上游更新后记得删。
    package =
      (import "${inputs.sops-nix}/default.nix" {
        pkgs = pkgs.extend (_final: prev: {
          buildGo125Module = prev.buildGoModule;
        });
      }).sops-install-secrets;

    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    useSystemdActivation = true;
    defaultSopsFile = ../secrets/secrets.yaml;
    secrets = {
      mihomo_env = {
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };
  };
}
