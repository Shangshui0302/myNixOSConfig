{ config, lib, pkgs, ... }:
let
  containerNames = [ "arch" "fedora" "ubuntu" ];
  hostHome = config.home.homeDirectory;

  distroboxImages = pkgs.writeShellApplication {
    name = "distrobox-images";
    runtimeInputs = with pkgs; [
      coreutils
      distrobox
      podman
    ];
    text = builtins.readFile ./container-images/manage.sh;
  };

  containerHomeFiles = lib.listToAttrs (lib.concatMap (name:
    let
      containerHome = "distrobox/${name}";
      hostLink = target: config.lib.file.mkOutOfStoreSymlink "${hostHome}/${target}";
    in
    [
      {
        name = "${containerHome}/.bashrc";
        value = {
          source = hostLink ".bashrc";
          force = true;
        };
      }
      {
        name = "${containerHome}/.config/fish";
        value = {
          source = hostLink ".config/fish";
          force = true;
        };
      }
      {
        name = "${containerHome}/.config/starship.toml";
        value = {
          source = hostLink ".config/starship.toml";
          force = true;
        };
      }
      {
        name = "${containerHome}/.config/blesh/init.sh";
        value = {
          source = hostLink ".config/blesh/init.sh";
          force = true;
        };
      }
      {
        name = "${containerHome}/.config/nvim/init.lua";
        value = {
          source = ./nvim/init.lua;
          force = true;
        };
      }
      {
        name = "${containerHome}/.local/bin/nvim";
        value = {
          source = "${config.programs.neovim.finalPackage}/bin/nvim";
          force = true;
        };
      }
      {
        name = "${containerHome}/.local/bin/starship";
        value = {
          source = "${pkgs.starship}/bin/starship";
          force = true;
        };
      }
    ]) containerNames);
in
{
  # 容器与虚拟化的用户侧工具（libvirtd 系统服务在 host/base/virtualization.nix）。
  home.packages = with pkgs; [
    distrobox
    distroboxImages
    virt-manager
  ];

  # 容器 home 是持久状态；由 HM 持续维护其中的配置入口和 Nix 包装器。
  home.file = containerHomeFiles;

  # 镜像配方由 Home Manager 部署；Podman 镜像和容器仍是可变运行状态。
  xdg.configFile = {
    "distrobox/images/arch.Containerfile".source = ./container-images/arch.Containerfile;
    "distrobox/images/fedora.Containerfile".source = ./container-images/fedora.Containerfile;
    "distrobox/images/ubuntu.Containerfile".source = ./container-images/ubuntu.Containerfile;
    "distrobox/distrobox.ini".text = ''
      # ==========================================
      # 1. arch all-in-one
      # ==========================================
      [arch]
      image=localhost/distrobox-arch:managed
      home=~/distrobox/arch
      init_hooks=sudo chsh -s /usr/bin/fish $USER
      additional_flags="--hostname=arch-dbx --privileged"
      volume="/etc/profiles:/etc/profiles:ro"

      # ==========================================
      # 2. fedora开发容器
      # ==========================================
      [fedora]
      image=localhost/distrobox-fedora:managed
      home=~/distrobox/fedora
      init_hooks=sudo chsh -s /usr/bin/fish $USER
      additional_flags="--hostname=fedora-dbx --privileged"
      volume="/etc/profiles:/etc/profiles:ro"

      # ==========================================
      # 3. 备用开发容器
      # ==========================================
      [ubuntu]
      image=localhost/distrobox-ubuntu:managed
      home=~/distrobox/ubuntu
      init_hooks=sudo chsh -s /usr/bin/fish $USER
      additional_flags="--hostname=ubuntu-dbx --privileged"
      volume="/etc/profiles:/etc/profiles:ro"
    '';
  };
}
