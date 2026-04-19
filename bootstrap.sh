#!/bin/bash
set -euo pipefail

# Install all the dotfiles

# Rudimentary flags parsing
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]
then
  usage='Usage: ./bootstrap.sh'
  echo "$usage"
  exit 1
fi

# Get bootstrap script directory
THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )
export DOTFILES="$THIS_DIR"

function backupFile ()
{
  local file=$1

	if [ -e ~/"$file" -a ! -L ~/"$file" ]; then
    echo "Backing up ${file}"
		mv ~/"$file" ~/"${file}".backup
  fi
}

function linkFileToHome ()
{
  echo "Creating a symlink for ${2}"
  rm -f ~/"${2}"
  ln -sf "${THIS_DIR}/${1}" ~/"${2}"
}

# Backup existing files and replace with symlinks
# files=(
#   ".bash_profile"
#   ".config/nvim/init.vim"
#   ".gitconfig"
#   ".zshrc"
# )
# for file in "${files[@]}"; do
#   backupFile file
#   echo "Creating a symlink for ${file}"
# 	ln -sf ${THIS_DIR}/${file} ~/${file}
# done

# Setup dev and gopath
mkdir -p "$HOME/dev/bin" || true
mkdir -p ~/dev/go/pkg
mkdir -p ~/dev/go/src/github.com/tribou || true
mkdir -p ~/dev/go/src/bitbucket.org || true
mkdir -p ~/dev/go/src/github.com/rocksauce || true
export GOPATH=~/dev/go

# Install z (rupa/z) for directory jumping
if [ ! -d "$HOME/dev/z" ]; then
  echo "Installing z..."
  git clone https://github.com/rupa/z.git "$HOME/dev/z"
fi

# .bash_profile
backupFile ".bash_profile"
linkFileToHome bash_profile .bash_profile

# .vimrc
backupFile ".vimrc"
linkFileToHome init.vim .vimrc

# .gitconfig
backupFile ".gitconfig"
linkFileToHome gitconfig .gitconfig

# .zshrc
backupFile ".zshrc"
linkFileToHome "zshrc" ".zshrc"

# .tmux.conf
backupFile ".tmux.conf"
linkFileToHome "tmux/tmux-conf" ".tmux.conf"

# mise default packages
linkFileToHome "default-node-packages" ".default-node-packages"
linkFileToHome "default-gems" ".default-gems"
linkFileToHome "default-python-packages" ".default-python-packages"

tic -x tmux/xterm-256color-italic.terminfo || true
tic -x tmux/tmux-256color.terminfo || true

# .gnupg/gpg-agent.conf
mkdir -p ~/.gnupg
backupFile ".gnupg/gpg-agent.conf"
linkFileToHome "gpg-agent-conf" ".gnupg/gpg-agent.conf"
  chown -R "$(whoami)" ~/.gnupg/
  chmod 600 ~/.gnupg/* || true
  chmod 700 ~/.gnupg
# Restart gpg-agent
if [ "$(which gpgconf)" ] && [ "$(which gpg-agent)" ]
then
  echo "Restarting gpg-agent"
  gpgconf --kill gpg-agent
  eval "$(gpg-agent --daemon 2>/dev/null)" || true
fi

# .config/nvim/init.vim
# Exceptional Case: need to link to the same .vimrc for nvim
mkdir -p ~/.config/nvim
backupFile ".config/nvim/init.vim"
linkFileToHome "init.vim" ".config/nvim/init.vim"

# .config/alacritty/alacritty.toml
mkdir -p ~/.config/alacritty
backupFile ".config/alacritty/alacritty.toml"
linkFileToHome "alacritty.toml" ".config/alacritty/alacritty.toml"

# .config/mise/config.toml
mkdir -p ~/.config/mise
backupFile ".config/mise/config.toml"
linkFileToHome "mise-config.toml" ".config/mise/config.toml"

# .config/nvim/coc-settings.json
backupFile ".config/nvim/coc-settings.json"
linkFileToHome "coc-settings.json" ".config/nvim/coc-settings.json"

# .claude/skills
mkdir -p ~/.claude
backupFile ".claude/skills"
linkFileToHome "skills" ".claude/skills"

# setup API keys file
if [ ! -f "$HOME/.ssh/api_keys" ]
then
  touch "$HOME/.ssh/api_keys"
fi

# Setup ssh key
if [ ! -f "$HOME/.ssh/id_rsa" ]
then
  ssh-keygen -t rsa -b 4096 -C "tribou@users.noreply.github.com" -N "" -f "$HOME/.ssh/id_rsa"
fi
if [ ! -f "$HOME/.ssh/id_ed25519" ]
then
  ssh-keygen -t ed25519 -C "tribou@users.noreply.github.com"
fi
## If macOS
if [[ "$OSTYPE" == "darwin"* ]] && ! grep -q "AddKeysToAgent" ~/.ssh/config
then

  if [ ! -f "$HOME/.ssh/config" ]
  then
    touch "$HOME/.ssh/config"
  else
    echo "" >> "$HOME/.ssh/config"
  fi

  echo "Host *" >> "$HOME/.ssh/config"
  echo "  AddKeysToAgent yes" >> "$HOME/.ssh/config"
  echo "  UseKeychain yes" >> "$HOME/.ssh/config"
  echo "  IdentityFile ~/.ssh/id_ed25519" >> "$HOME/.ssh/config"
fi

# Setup ssh-agent
## If agent socket isn't available, source it
[ -s "${SSH_AUTH_SOCK:-}" ] || eval "$(ssh-agent -s)"
## Add keys to keychain
if [[ "$OSTYPE" == "darwin"* ]]; then
  # --apple-use-keychain replaces -K (removed in macOS Ventura 13+); fall back to plain ssh-add
  [ -f "$HOME/.ssh/id_rsa" ] && { ssh-add --apple-use-keychain "$HOME/.ssh/id_rsa" 2>/dev/null || ssh-add "$HOME/.ssh/id_rsa" 2>/dev/null || true; }
  [ -f "$HOME/.ssh/id_ed25519" ] && { ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519" 2>/dev/null || ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || true; }
else
  [ -f "$HOME/.ssh/id_rsa" ] && ssh-add "$HOME/.ssh/id_rsa" || true
  [ -f "$HOME/.ssh/id_ed25519" ] && ssh-add "$HOME/.ssh/id_ed25519" || true
fi

# Install tmux plugins
[ ! -d "$HOME/.tmux/plugins/tpm" ] && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins/tpm/" "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true

# Source all lib scripts
. "$DOTFILES/lib/index.sh"

if   command -v curl &>/dev/null
then

  if   ! command -v cargo &>/dev/null
    then
      _BOOTSTRAP_INSTALL="curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
      echo "Installing rust:"
      echo "$_BOOTSTRAP_INSTALL"
      echo
      eval "$_BOOTSTRAP_INSTALL"
      export PATH="$HOME/.cargo/bin:$PATH"
      [ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
      echo
    fi

    export PATH="$HOME/.local/bin:$PATH"
    MISE_BIN="$(type -P mise 2>/dev/null || true)"

    if [ -z "$MISE_BIN" ] && [ -x "$HOME/.local/bin/mise" ]
    then
      MISE_BIN="$HOME/.local/bin/mise"
    fi

    if [ -z "$MISE_BIN" ]
    then
      echo "Installing mise:"
      curl https://mise.run | sh
      echo
      MISE_BIN="$HOME/.local/bin/mise"
    fi

    if [ -x "$MISE_BIN" ]
    then
      eval "$("$MISE_BIN" activate bash)"
      # Install all tools from mise-config.toml (symlinked to ~/.config/mise/config.toml)
      mise install node go
      hash -r
      corepack enable
      # Try precompiled ruby first (fast), fall back to source compilation
      if ! MISE_RUBY_COMPILE=0 mise install ruby 2>/dev/null; then
        echo "No precompiled ruby available for this platform, compiling from source..."
        mise install ruby
      fi
      echo
    fi

  else
    echo "ERROR: curl not available! Skipping all installs"
    echo
  fi


  if  command -v npm &>/dev/null && ! command -v eslint_d &>/dev/null
  then
    _BOOTSTRAP_INSTALL="npm install --location=global neovim eslint_d editorconfig"
    echo "Installing global node modules:"
    echo "$_BOOTSTRAP_INSTALL"
    echo
    eval "$_BOOTSTRAP_INSTALL"
  else
    echo "npm not available or eslint_d already installed. Skipping..."
  fi

  if [ ! -f "$HOME/dev/z/z.sh" ]
  then
    echo "Installing z"
    git clone --depth 1 https://github.com/rupa/z.git ~/dev/z
    . "$HOME/dev/z/z.sh"
  fi

  # Install brew prerequisites on Linux (needed before brew can install)
  if [[ "$OSTYPE" != "darwin"* ]]; then
    if command -v apt-get &>/dev/null; then
      sudo apt-get update
      sudo apt-get install -y curl git build-essential xdg-utils bash-completion
    elif command -v pacman &>/dev/null; then
      sudo pacman -Syu --noconfirm curl git base-devel bash-completion
    fi
  fi

  # Install brew if not present (macOS and Linux)
  if ! command -v brew &>/dev/null; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ "$OSTYPE" == "darwin"* ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
    else
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
  fi

  # Brew is required — exit if still not available
  if ! command -v brew &>/dev/null; then
    echo "ERROR: Homebrew installation failed. Install brew manually and re-run."
    exit 1
  fi

  brew install \
      git \
      neovim \
      python \
      zlib \
      hashicorp/tap/terraform-ls \
      nmap \
      ansible \
      htop \
      gpg \
      editorconfig \
      watchman \
      tree \
      awscli \
      ssh-copy-id \
      git-extras \
      jq \
      dos2unix \
      tidy-html5 \
      fd \
      ripgrep \
      bat \
      navi \
      shellcheck \
      tlrc \
      lazydocker \
      lazygit \
      just \
      lynx \
      tree-sitter-cli \
      fzf \
      tmux \
      delta \
      git-delta \
      gh \
      beads

  # Linux-only packages
  if [[ "$OSTYPE" != "darwin"* ]]; then
    brew install gcc
  fi

  # macOS-only packages
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install \
      bash-completion \
      rename \
      alacritty \
      ngrok/ngrok/ngrok \
      reattach-to-user-namespace \
      tfenv \
      tor \
      vimpager \
      renameutils \
      tmux-mem-cpu-load

    brew install --cask \
      cmake \
      1password \
      1password-cli \
      appcleaner \
      balenaetcher \
      bruno \
      firefox \
      imageoptim \
      orbstack \
      steam \
      font-fira-code-nerd-font \
      font-hack-nerd-font \
      font-fontawesome
  fi

  # vim-plug + Neovim plugins — must run after brew installs neovim
  if command -v nvim &>/dev/null && [ ! -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ]
  then
    echo "Installing vim-plug for Neovim"
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    echo "Installing Neovim plugins"
    nvim --headless +"PlugInstall --sync" +qall
  fi

  # pynvim (Neovim Python support) — installed via pip since mise no longer manages Python
  if command -v python3 &>/dev/null && ! python3 -c "import pynvim" &>/dev/null
  then
    echo "Installing pynvim"
    pip3 install --user --break-system-packages pynvim
  fi

  # neovim gem (Neovim Ruby support) — installed via mise-managed ruby
  if command -v ruby &>/dev/null && ! gem list neovim -i &>/dev/null
  then
    echo "Installing neovim gem"
    gem install neovim
  fi

  # Golang tools — install after mise provisions Go
  GO_BIN_DIR="${GOBIN:-$GOPATH/bin}"
  if [ -x "$(which go)" ] && [ ! -x "$GO_BIN_DIR/gopls" ]
  then
    echo "Installing gopls"
    go install golang.org/x/tools/gopls@latest
  fi
