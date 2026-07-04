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
    fzf \
    fd-find \
    bat \
    git-delta \
  && rm -rf /var/lib/apt/lists/* \
  && pip3 install --break-system-packages pynvim \
  && ln -s /usr/bin/fdfind /usr/local/bin/fd \
  && ln -s /usr/bin/batcat /usr/local/bin/bat

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

# Install mise (replaces rbenv + nvm for Ruby and Node version management)
RUN bash -o pipefail -c "curl -fsSL https://mise.run | sh" \
  && ln -sf /root/.local/bin/mise /usr/local/bin/mise

# Install goss for infrastructure assertions
RUN curl -fsSL https://github.com/goss-org/goss/releases/latest/download/goss-linux-amd64 \
    -o /usr/local/bin/goss \
  && chmod +x /usr/local/bin/goss

WORKDIR /dotfiles

# Copy dotfiles — changes here don't bust the apt cache
COPY . .

# Symlink dotfiles configs (needed before plugin installs)
RUN mkdir -p ~/.config/nvim ~/.config/mise \
  && ln -sf /dotfiles/tmux/tmux-conf ~/.tmux.conf \
  && ln -sf /dotfiles/init.vim ~/.config/nvim/init.vim \
  && ln -sf /dotfiles/default-node-packages ~/.default-node-packages \
  && ln -sf /dotfiles/default-gems ~/.default-gems \
  && ln -sf /dotfiles/default-python-packages ~/.default-python-packages \
  && ln -sf /dotfiles/mise-config.toml ~/.config/mise/config.toml

# Install Go runtime + gopls via mise
ENV GOPATH=/root/dev/go
RUN mkdir -p "$GOPATH/bin" \
  && mise use -g go@latest \
  && eval "$(mise env bash)" \
  && go install golang.org/x/tools/gopls@latest
ENV PATH="/root/dev/go/bin:/root/.local/share/mise/shims:$PATH"

# Enable corepack (yarn, pnpm)
RUN corepack enable

# Install TPM and all tmux plugins
RUN git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm \
  && git clone --depth 1 https://github.com/tmux-plugins/tmux-sensible ~/.tmux/plugins/tmux-sensible \
  && git clone --depth 1 https://github.com/tmux-plugins/tmux-resurrect ~/.tmux/plugins/tmux-resurrect \
  && git clone --depth 1 https://github.com/thewtex/tmux-mem-cpu-load ~/.tmux/plugins/tmux-mem-cpu-load \
  && git clone --depth 1 https://github.com/tmux-plugins/tmux-copycat ~/.tmux/plugins/tmux-copycat \
  && git clone --depth 1 https://github.com/tmux-plugins/tmux-open ~/.tmux/plugins/tmux-open \
  && git clone --depth 1 https://github.com/tmux-plugins/tmux-yank ~/.tmux/plugins/tmux-yank \
  && git clone --depth 1 https://github.com/tmux-plugins/tmux-prefix-highlight ~/.tmux/plugins/tmux-prefix-highlight

# Install vim-plug and Neovim plugins
RUN curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
  && nvim --headless +PlugInstall +qall 2>/dev/null

# Install CoC extensions via npm
RUN mkdir -p ~/.config/coc/extensions \
  && cd ~/.config/coc/extensions \
  && echo '{"dependencies":{}}' > package.json \
  && npm install --install-strategy=shallow --ignore-scripts --no-bin-links \
     coc-tsserver coc-pairs coc-css coc-highlight coc-json coc-git \
     coc-snippets coc-eslint coc-emoji coc-solargraph coc-yaml coc-html \
     coc-lists coc-svg 2>/dev/null

# Install GNU parallel for bats --jobs backend
RUN apt-get update && apt-get install -y parallel \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p ~/.parallel && touch ~/.parallel/will-cite

# Mark bootstrap as complete
RUN touch ~/.dotfiles-bootstrap-done
