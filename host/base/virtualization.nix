{ ... }: {
  # libvirtd 虚拟化（原在 gaming.nix；virt-manager 用户端在 home/dev/containers.nix）。
  virtualisation.libvirtd.enable = true;

  users.users.lishangshui.extraGroups = [ "libvirtd" ];
}
