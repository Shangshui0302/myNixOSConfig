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

  # host-spawn 会原样继承容器当前目录；/run/host/... 在宿主上并不存在。
  distroboxXdgOpen = pkgs.writeShellScript "distrobox-xdg-open" ''
    host_home="''${DISTROBOX_HOST_HOME:-$HOME}"
    exec host-spawn -cwd "$host_home" --no-pty xdg-open "$@"
  '';

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
      # 容器里的 ssh / git / dsh-ssh 插件都按 $HOME/.ssh 找 config、known_hosts 和私钥；
      # 不链到宿主 home 的话 OpenSSH 会自己建一个空目录，导致 Host key verification
      # failed / no such identity（而私钥其实躺在宿主 home 里）。
      {
        name = "${containerHome}/.ssh";
        value = {
          source = hostLink ".ssh";
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
      {
        name = "${containerHome}/.local/bin/xdg-open";
        value = {
          source = distroboxXdgOpen;
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

  # 上游生成的入口会写死当时的 store 路径；由 HM 随 generation 一起更新并保活。
  xdg.desktopEntries = lib.genAttrs containerNames (name:
    let
      displayName = { arch = "Arch"; fedora = "Fedora"; ubuntu = "Ubuntu"; }.${name};
    in {
      name = displayName;
      genericName = "Terminal entering ${displayName}";
      comment = "Terminal entering ${displayName}";
      exec = "${pkgs.distrobox}/bin/distrobox enter ${name}";
      icon = "${hostHome}/.local/share/icons/distrobox/${name}.png";
      terminal = true;
      categories = [ "System" "Utility" ];
      settings = {
        TryExec = "${pkgs.distrobox}/bin/distrobox";
        Keywords = "distrobox;";
      };
      actions.Remove = {
        name = "Remove ${displayName} from system";
        exec = "${pkgs.distrobox}/bin/distrobox rm ${name}";
      };
    });

  # 用户目录中的旧入口优先于 profile；用同一份生成结果接管，直接替换这些受管理入口，不生成备份。
  xdg.dataFile = lib.listToAttrs (map (name: {
    name = "applications/${name}.desktop";
    value.source = "${config.home.path}/share/applications/${name}.desktop";
    value.force = true;
  }) containerNames);

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
