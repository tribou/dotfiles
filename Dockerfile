FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DOTFILES=/dotfiles

# Native bootstrap prerequisites — cached layer, only re-runs when this block changes.
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    git \
    build-essential \
    zlib1g-dev \
    xdg-utils \
    bash-completion \
    sudo \
    file \
    tar \
    gzip \
    bzip2 \
    unzip \
    zip \
    xz-utils \
    zstd \
    python3-apt \
    locales \
  && locale-gen en_US.UTF-8 \
  && rm -rf /var/lib/apt/lists/*

# Install goss for infrastructure assertions (v0.4.9+ ships versioned tarballs,
# not bare binaries, so latest/download/goss-linux-amd64 404s)
RUN GOSS_VERSION=v0.4.10 \
  && GOSS_ARCH=$(uname -m | sed 's/aarch64/arm64/') \
  && curl -fsSL "https://github.com/goss-org/goss/releases/download/${GOSS_VERSION}/goss_${GOSS_VERSION#v}_linux_${GOSS_ARCH}.tar.gz" \
      | tar xz -C /usr/local/bin goss \
  && chmod +x /usr/local/bin/goss

# Configure git safe directory to allow operations across host/container UID boundaries and worktrees
RUN git config --system --add safe.directory "*"

WORKDIR /dotfiles

# Copy dotfiles — changes here don't bust the apt cache
COPY . .
