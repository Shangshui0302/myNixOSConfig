FROM quay.io/toolbx/arch-toolbox@sha256:d6a3baf2e9370276b110ddf6dc7b616528ba6cb38fd017e366cdb242af499fa1

ARG PARU_COMMIT=329be2113c590046cb29858c23d9b96a8d7bd586
ARG CODE_SERVER_COMMIT=e84a7da7a16a0fb9842974c39182b9eb5d00dd0e

RUN pacman -Syu --noconfirm && \
    pacman -S --needed --noconfirm \
      base-devel bash-completion bat bc btop curl eza fastfetch fd fish \
      flatpak-xdg-utils fzf git glibc-locales grc inetutils lsof man-db \
      man-pages mesa mtr neovim nodejs npm nss-mdns openssh pigz plocate \
      ripgrep rsync starship sudo tcpdump time traceroute tree unzip \
      vte-common vulkan-intel vulkan-radeon wget words xorg-xauth zip zoxide && \
    useradd --create-home builder && \
    printf 'builder ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/90-image-builder && \
    chmod 0440 /etc/sudoers.d/90-image-builder

USER builder
WORKDIR /tmp

RUN git clone https://aur.archlinux.org/paru.git && \
    git -C paru checkout "$PARU_COMMIT" && \
    cd paru && \
    makepkg --syncdeps --install --noconfirm --needed

RUN git clone https://aur.archlinux.org/code-server.git && \
    git -C code-server checkout "$CODE_SERVER_COMMIT" && \
    cd code-server && \
    makepkg --syncdeps --install --noconfirm --needed

USER root
WORKDIR /

RUN userdel --remove builder && \
    rm -f /etc/sudoers.d/90-image-builder && \
    pacman -Scc --noconfirm
