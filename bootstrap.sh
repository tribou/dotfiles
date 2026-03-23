#!/bin/bash

# Install all the dotfiles

# Rudimentary flags parsing
if [ "$1" = "-h" ] || [ "$1" = "--help" ]
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
mkdir ~/dev/go/pkg || true
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

tic -x tmux/xterm-256color-italic.terminfo
tic -x tmux/tmux-256color.terminfo

# .gnupg/gpg-agent.conf
mkdir -p ~/.gnupg
backupFile ".gnupg/gpg-agent.conf"
linkFileToHome "gpg-agent-conf" ".gnupg/gpg-agent.conf"
chown -R "$(whoami)" ~/.gnupg/
chmod 600 ~/.gnupg/*
chmod 700 ~/.gnupg
# Restart gpg-agent
if [ "$(which gpgconf)" ] && [ "$(which gpg-agent)" ]
then
  echo "Restarting gpg-agent"
  gpgconf --kill gpg-agent
  eval "$(gpg-agent --daemon 2>/dev/null)"
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

# .config/nvim/coc-settings.json
backupFile ".config/nvim/coc-settings.json"
linkFileToHome "coc-settings.json" ".config/nvim/coc-settings.json"

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
[ -s "$SSH_AUTH_SOCK" ] || eval `ssh-agent -s`
## Add keys to keychain
if [[ "$OSTYPE" == "darwin"* ]]; then
  [ -f "$HOME/.ssh/id_rsa" ] && ssh-add -K "$HOME/.ssh/id_rsa" > /dev/null 2>&1
  [ -f "$HOME/.ssh/id_ed25519" ] && ssh-add -K "$HOME/.ssh/id_ed25519" > /dev/null 2>&1
else
  [ -f "$HOME/.ssh/id_rsa" ] && ssh-add "$HOME/.ssh/id_rsa"
  [ -f "$HOME/.ssh/id_ed25519" ] && ssh-add "$HOME/.ssh/id_ed25519"
fi

# Install tmux plugins
[ ! -d "$HOME/.tmux/plugins/tpm" ] && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
"$HOME/.tmux/plugins/tpm/bin/install_plugins"

# Source all lib scripts
. "$DOTFILES/lib/index.sh"

# Install dependencies
source "./scripts/install.sh"

if   [ -s "$(which curl)"  ]
then

  if   [ ! -s "$(which cargo)"  ]
    then
      _BOOTSTRAP_INSTALL="curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
      echo "Installing rust:"
      echo "$_BOOTSTRAP_INSTALL"
      echo
      eval "$_BOOTSTRAP_INSTALL"
      export PATH="$HOME/.cargo/bin:$PATH"
      [ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
      echo
    fi

    if [ ! -x "$HOME/.local/bin/mise" ]
    then
      echo "Installing mise:"
      curl https://mise.run | sh
      export PATH="$HOME/.local/bin:$PATH"
      eval "$("$HOME/.local/bin/mise" activate bash)"
      echo
    fi

    if [ -x "$HOME/.local/bin/mise" ]
    then
      mise use -g node@lts
      mise use -g ruby@3
      mise use -g python@3
      echo
    fi

  else
    echo "ERROR: curl not available! Skipping all installs"
    echo
  fi


  if  [ -s "$(which npm)"  ] && [ ! -n "$(which eslint_d)" ]
  then
    _BOOTSTRAP_INSTALL="npm install --location=global neovim eslint_d editorconfig"
    echo "Installing global node modules:"
    echo "$_BOOTSTRAP_INSTALL"
    echo
    eval "$_BOOTSTRAP_INSTALL"
  else
    echo "npm not available or eslint_d already installed. Skipping..."
  fi

  if [ ! -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ]
  then
    echo "Installing vim-plug for Neovim"
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    echo "Installing Neovim plugins"
    nvim --headless +"PlugInstall --sync" +qall
  fi

  if [ ! -f "$HOME/dev/z/z.sh" ]
  then
    echo "Installing z"
    git clone --depth 1 https://github.com/rupa/z.git ~/dev/z
    . "$HOME/dev/z/z.sh"
  fi

  if [ ! -s "$(which fzf)"  ]
  then
    echo "Installing fzf"
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
  fi


  if [[ "$OSTYPE" == "darwin"* ]]; then
    _PKG_MANAGER="brew"
  elif command -v apt-get &>/dev/null; then
    _PKG_MANAGER="apt"
  elif command -v pacman &>/dev/null; then
    _PKG_MANAGER="pacman"
  else
    echo "Unsupported package manager. Install packages manually."
    exit 1
  fi

  if [ "$_PKG_MANAGER" = "brew" ] && [ ! -s "$(which brew)" ]; then
    echo "Brew not installed. Skipping the rest of the installs"
    exit 0
  fi

  if [ "$_PKG_MANAGER" = "brew" ]; then
    if [ ! -s "$(which tfenv)" ]
    then
      echo "Installing tfenv"
      if [ -s "$(brew list terraform)"  ]
      then
        echo "Existing terraform install. Unlinking..."
        brew unlink terraform
        echo
      fi
      brew install tfenv
      tfenv install
      tfenv use
      echo
    fi
  fi

  JAVA_VERSION=17

  if [ "$_PKG_MANAGER" = "brew" ]; then
    if [ ! -s "$(which java)" ]
    then
      echo "Installing java"
      brew install "zulu@$JAVA_VERSION"
      echo
    fi
  fi

  if [ "$_PKG_MANAGER" = "brew" ]; then
    if [ ! -s "$(which jenv)" ]
    then
      echo "Installing jenv"
      if [ -s "$(brew list jenv)"  ]
      then
        echo "Existing jenv install. Unlinking..."
        brew unlink jenv
        echo
      fi
      brew install jenv
      eval "$(jenv init -)"
      jenv add "$(/usr/libexec/java_home)"
      jenv global $JAVA_VERSION
      echo
    fi
  fi

  if [ "$_PKG_MANAGER" = "brew" ]; then
    if [ -z "$(brew list --cask font-fira-code-nerd-font)" ]
    then
      _BOOTSTRAP_INSTALL="brew tap homebrew/cask-fonts && brew install --cask font-fira-code-nerd-font font-hack-nerd-font font-fontawesome"
      echo "Installing fonts:"
      echo "$_BOOTSTRAP_INSTALL"
      echo
      eval "$_BOOTSTRAP_INSTALL"
      echo
    else
      echo "Fonts already installed Skipping..."
      echo
    fi
  fi

  if [ "$_PKG_MANAGER" = "brew" ]; then
    if [ ! -s "$(which tmux)"  ]
    then
      echo "Installing tmux"
      brew install tmux
    fi
  fi

  if [ "$_PKG_MANAGER" = "brew" ]; then
    brew install git \
      alacritty \
      neovim \
      python \
      bash-completion \
      zlib \
      hashicorp/tap/terraform-ls \
      homebrew/core/nmap \
      homebrew/core/go \
      elixir \
      ansible \
      htop \
      tor \
      gpg \
      editorconfig \
      watchman \
      tree \
      awscli \
      ssh-copy-id \
      git-extras \
      vimpager \
      jq \
      dos2unix \
      tidy-html5 \
      fd \
      ripgrep \
      bat \
      rename \
      navi \
      ngrok/ngrok/ngrok \
      renameutils \
      shellcheck \
      tmux-mem-cpu-load \
      reattach-to-user-namespace \
      tldr \
      lazydocker \
      lazygit \
      just

  elif [ "$_PKG_MANAGER" = "apt" ]; then
    sudo apt-get update
    sudo apt-get install -y \
      git \
      bash-completion \
      nmap \
      golang \
      htop \
      gnupg \
      tree \
      awscli \
      ssh-copy-id \
      jq \
      dos2unix \
      tidy \
      fd-find \
      ripgrep \
      bat \
      rename \
      shellcheck \
      tldr \
      just \
      cmake \
      build-essential \
      libssl-dev \
      libreadline-dev \
      zlib1g-dev \
      libyaml-dev \
      xdg-utils
    # On Ubuntu/Debian, some tools install with different binary names to avoid
    # conflicts with pre-existing packages. Create canonical symlinks in ~/.local/bin.
    mkdir -p "$HOME/.local/bin"
    [ -x "$(which fdfind 2>/dev/null)" ] && ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
    [ -x "$(which batcat 2>/dev/null)" ] && ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
    # lazygit — not in apt, install via release script
    if [ ! -s "$(which lazygit)" ]; then
      LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
      curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
      tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
      sudo install /tmp/lazygit /usr/local/bin
    fi
    # neovim — apt version (0.9.x) is too old for plugins requiring vim.uv (needs 0.10+)
    if [ ! -s "$(which nvim)" ]; then
      _NVIM_ARCH=$(uname -m | sed 's/aarch64/arm64/')
      curl -fsSL "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-${_NVIM_ARCH}.tar.gz" \
        | sudo tar xz -C /opt
      sudo ln -sf "/opt/nvim-linux-${_NVIM_ARCH}/bin/nvim" /usr/local/bin/nvim
    fi

  elif [ "$_PKG_MANAGER" = "pacman" ]; then
    sudo pacman -Syu --noconfirm \
      git \
      neovim \
      bash-completion \
      nmap \
      go \
      htop \
      gnupg \
      tree \
      aws-cli \
      openssh \
      jq \
      dos2unix \
      tidy \
      fd \
      ripgrep \
      bat \
      perl-rename \
      shellcheck \
      tldr \
      just \
      cmake \
      base-devel \
      xdg-utils
    # lazygit — available in AUR; install via yay if present, else release script
    if [ ! -s "$(which lazygit)" ]; then
      if command -v yay &>/dev/null; then
        yay -S --noconfirm lazygit
      else
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
        sudo install /tmp/lazygit /usr/local/bin
      fi
    fi
  fi

  if [ "$_PKG_MANAGER" = "brew" ]; then
    brew install --cask \
      homebrew/cask/cmake \
      1password \
      1password-cli \
      appcleaner \
      balenaetcher \
      bruno \
      firefox \
      imageoptim \
      orbstack \
      steam
  fi


  # Golang tools
  go install golang.org/x/tools/gopls@latest
