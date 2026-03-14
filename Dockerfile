FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# System deps — cached layer, only re-runs when this block changes
RUN apt-get update && apt-get install -y \
    tmux \
    neovim \
    git \
    curl \
    python3 \
    python3-pip \
  && rm -rf /var/lib/apt/lists/*

# Install goss for infrastructure assertions
RUN curl -fsSL https://github.com/goss-org/goss/releases/latest/download/goss-linux-amd64 \
    -o /usr/local/bin/goss \
  && chmod +x /usr/local/bin/goss

WORKDIR /dotfiles

# Copy dotfiles — changes here don't bust the apt cache
COPY . .
