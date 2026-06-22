{ ... }: {
  xdg.configFile."distrobox/distrobox.ini".text = ''
    # ==========================================
    # 1. arch all-in-one
    # ==========================================
    [arch]
    image=arch_rolling:init
    home=~/distrobox/arch
    init_hooks=sudo chsh -s /usr/bin/fish $USER


    # ==========================================
    # 2. fedora开发容器
    # ==========================================
    [fedora]
    image=fedora_43:init
    home=~/distrobox/fedora
    init_hooks=sudo chsh -s /usr/bin/fish $USER

    # ==========================================
    # 3. 备用开发容器
    # ==========================================
    [ubuntu]
    image=ubuntu_24.04:init
    home=~/distrobox/ubuntu
    init_hooks=sudo chsh -s /usr/bin/fish $USER
  '';
}
