{ pkgs, ... }: {
  home.packages = with pkgs; [ distrobox ];

  xdg.configFile."distrobox/distrobox.ini".text = ''
    # ==========================================
    # 1. arch all-in-one
    # ==========================================
    [arch]
    image=arch_rolling:2026-07-03
    home=~/distrobox/arch
    init_hooks=sudo chsh -s /usr/bin/fish $USER
    additional_flags="--hostname=arch-dbx --privileged"
    volume="/etc/profiles:/etc/profiles:ro"

    # ==========================================
    # 2. fedora开发容器
    # ==========================================
    [fedora]
    image=fedora_43:2026-07-03
    home=~/distrobox/fedora
    init_hooks=sudo chsh -s /usr/bin/fish $USER
    additional_flags="--hostname=fedora-dbx --privileged"
    volume="/etc/profiles:/etc/profiles:ro"

    # ==========================================
    # 3. 备用开发容器
    # ==========================================
    [ubuntu]
    image=ubuntu_24.04:2026-07-03
    home=~/distrobox/ubuntu
    init_hooks=sudo chsh -s /usr/bin/fish $USER
    additional_flags="--hostname=ubuntu-dbx --privileged"
    volume="/etc/profiles:/etc/profiles:ro"
  '';
}
