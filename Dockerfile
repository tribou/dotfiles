FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DOTFILES=/dotfiles

# System deps — cached layer, only re-runs when this block changes
RUN apt-get update && apt-get install -y \
    tmux \
    git \
    curl \
    python3 \
    python3-pip \
  && rm -rf /var/lib/apt/lists/* \
  && pip3 install --break-system-packages pynvim

# Install Node.js 24 via NodeSource (matches bootstrap.sh)
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/*

# Install neovim from official stable release — Ubuntu 24.04 apt ships 0.9.5
# which is too old for plugins requiring vim.uv (needs 0.10+)
RUN ARCH=$(uname -m | sed 's/aarch64/arm64/') \
  && curl -fsSL "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-${ARCH}.tar.gz" \
      | tar xz -C /opt \
  && ln -sf "/opt/nvim-linux-${ARCH}/bin/nvim" /usr/local/bin/nvim

# Install goss for infrastructure assertions
RUN curl -fsSL https://github.com/goss-org/goss/releases/latest/download/goss-linux-amd64 \
    -o /usr/local/bin/goss \
  && chmod +x /usr/local/bin/goss

WORKDIR /dotfiles

# Copy dotfiles — changes here don't bust the apt cache
COPY . .
