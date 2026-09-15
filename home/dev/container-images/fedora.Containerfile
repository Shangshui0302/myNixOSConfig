FROM registry.fedoraproject.org/fedora-toolbox@sha256:8449afb43a8730662d520e95e56efa0500c75627212ea517e4329700d0288391

ARG CODE_SERVER_VERSION=4.125.0

RUN dnf upgrade --refresh -y && \
    dnf install -y \
      @development-tools arm-none-eabi-binutils-cs arm-none-eabi-gcc-cs \
      arm-none-eabi-newlib bash-completion bat bc btop cmake curl docker-cli \
      eza fastfetch fd-find fish fzf gawk git gnupg2 grc lsof make man-db \
      man-pages minicom mtr neovim nodejs nodejs-npm nss-mdns openocd \
      openssh-clients picocom pigz python3 ripgrep rsync stlink sudo \
      tcpdump time traceroute tree unzip uv wget2-wget whois words \
      xorg-x11-xauth xz yarnpkg zip zoxide && \
    curl --fail --location --output /tmp/code-server.rpm \
      "https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-amd64.rpm" && \
    dnf install -y /tmp/code-server.rpm && \
    rm -f /tmp/code-server.rpm && \
    dnf clean all
