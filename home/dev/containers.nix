{ ... }: {
  xdg.configFile."distrobox/distrobox.ini".text = ''
    [arch]
    image=quay.io/toolbx/arch-toolbox:latest

    [ubuntu]
    image=docker.io/library/ubuntu:latest
  '';
}
