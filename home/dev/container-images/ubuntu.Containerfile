FROM quay.io/toolbx/ubuntu-toolbox@sha256:2000ed7af9098f1792a37be694c5d28a5829e89f8e57533cc71f7cb44e009870

ARG CODE_SERVER_VERSION=4.125.0
ARG STARSHIP_VERSION=1.25.1

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      bash-completion bat bc btop build-essential bzip2 curl dialog eza \
      fd-find fish flatpak-xdg-utils fzf gawk git gnupg2 grc iproute2 \
      iputils-ping language-pack-en less lsof make man-db manpages \
      mesa-vulkan-drivers mtr neovim openssh-client pigz procps python3-pip \
      python3-venv ripgrep rsync sudo tcpdump time traceroute tree unzip \
      wget xauth xz-utils zip zoxide zsh && \
    curl --fail --location --output /tmp/code-server.deb \
      "https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server_${CODE_SERVER_VERSION}_amd64.deb" && \
    apt-get install -y /tmp/code-server.deb && \
    curl --fail --location \
      "https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz" \
      | tar --extract --gzip --directory /usr/local/bin starship && \
    rm -f /tmp/code-server.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
