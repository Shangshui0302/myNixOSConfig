{ config, lib, pkgs, ... }: {
  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  environment.systemPackages = with pkgs; [
    distrobox
  ];

  # 覆盖 registries.conf：Docker Hub 走 docker.1ms.run 镜像
  environment.etc."containers/registries.conf".text = lib.mkForce ''
    unqualified-search-registries = ["docker.io", "quay.io"]

    [[registry]]
    prefix = "docker.io"
    location = "docker.1ms.run"

    [[registry]]
    prefix = "quay.io"
    location = "quay.io"
  '';

  # podman 走 mihomo HTTP 代理
  environment.etc."containers/containers.conf.d/01-proxy.conf".text = ''
    [engine]
    env = ["http_proxy=http://127.0.0.1:7890","https_proxy=http://127.0.0.1:7890"]
  '';
}
