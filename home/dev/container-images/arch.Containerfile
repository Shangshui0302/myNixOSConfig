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

# distrobox/Arch 基础镜像装了 nss-mdns，但 nsswitch.conf 不引用它，所以容器里解析不了
# 局域网 .local 主机名（症状：容器内 ssh/git/dsh-ssh 报 getaddrinfo ENOTFOUND xxx.local）。
# mdns4_minimal 必须排在 resolve/dns 之前，否则 .local 查询会先被判成 NOTFOUND 而终止。
# 末尾两条 grep 是断言：基础镜像若换掉这行，构建会直接失败而不是静默失效。
RUN sed -i -E \
      's|^hosts:.*|hosts: mymachines mdns4_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns|' \
      /etc/nsswitch.conf && \
    grep -qE '^hosts:.*mdns4_minimal' /etc/nsswitch.conf && \
    grep -n '^hosts:' /etc/nsswitch.conf

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
