#!/bin/bash

# Install all the dotfiles

# Rudimentary flags parsing
if [ "$1" = "-h" ] || [ "$1" = "--help" ]
then
  usage='Usage: ./bootstrap.sh [-i|--install-deps]'
  echo "$usage"
  exit 1
fi

# Get bootstrap script directory
THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )

function backupFile ()
{
  local file=$1

	if [ -e ~/$file -a ! -L ~/$file ]; then
    echo "Backing up ${file}"
		mv ~/$file ~/${file}.backup
  fi
}

function linkFileToHome ()
{
  echo "Creating a symlink for ${2}"
  ln -sf ${THIS_DIR}/${1} ~/${2}
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
mkdir -p $HOME/dev/bin || true
mkdir ~/dev/go/pkg || true
mkdir -p ~/dev/go/src/github.com/tribou || true
mkdir -p ~/dev/go/src/bitbucket.org || true
mkdir -p ~/dev/go/src/github.com/rocksauce || true
export GOPATH=~/dev/go

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
tic -x tmux/xterm-256color-italic.terminfo
tic -x tmux/tmux-256color.terminfo

# .gnupg/gpg-agent.conf
mkdir -p ~/.gnupg
backupFile ".gnupg/gpg-agent.conf"
linkFileToHome "gpg-agent-conf" ".gnupg/gpg-agent.conf"
chown -R $(whoami) ~/.gnupg/
chmod 600 ~/.gnupg/*
chmod 700 ~/.gnupg
# Restart gpg-agent
if [ $(which gpgconf) ] && [ $(which gpg-agent) ]
then
  echo "Restarting gpg-agent"
  gpgconf --kill gpg-agent
  eval $(gpg-agent --daemon 2>/dev/null)
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
[ -f "$HOME/.ssh/id_rsa" ] && (ssh-add -K "$HOME/.ssh/id_rsa" > /dev/null 2>&1 || ssh-add "$HOME/.ssh/id_rsa")
[ -f "$HOME/.ssh/id_ed25519" ] && (ssh-add -K "$HOME/.ssh/id_ed25519" > /dev/null 2>&1 || ssh-add "$HOME/.ssh/id_ed25519")

# Install tmux plugins
[ ! -d "$HOME/.tmux/plugins/tpm" ] && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Source all lib scripts
. "$DOTFILES/lib/index.sh"

# More rudimentary flags parsing
if [ "$1" = "-i" ] || [ "$1" = "--install-deps" ]
then
  echo "--install-deps detected. Installing dependencies..."
  echo

  source "./scripts/install.sh"

  if   [ -s "$(which curl)"  ]
  then

    if   [ ! -f "$HOME/.vim/autoload/plug.vim" ]
    then
      _BOOTSTRAP_INSTALL="sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'"
      echo "Installing vim-plug:"
      echo "$_BOOTSTRAP_INSTALL"
      echo
      eval "$_BOOTSTRAP_INSTALL"
      echo
    fi

    if   [ ! -s "$(which nvim)"  ] && [ ! -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ]
    then
      _BOOTSTRAP_INSTALL="curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
      echo "Installing vim-plug for neovim:"
      echo "$_BOOTSTRAP_INSTALL"
      echo
      eval "$_BOOTSTRAP_INSTALL"
      echo
    fi

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

    _BOOTSTRAP_INSTALL="curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash"
    echo "Installing nvm:"
    echo "$_BOOTSTRAP_INSTALL"
    echo
    eval "$_BOOTSTRAP_INSTALL"
    if [ ! -n "$(command -v nvm)" ]
    then
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh"  ] && source "$NVM_DIR/nvm.sh" # This loads nvm
      [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
    fi
    echo

    if [ -n "$(command -v nvm)" ] && [ ! -n "$(nvm ls 16 | grep 16)" ]
    then
      echo "Installing node 16, 18, 20:"
      echo
      nvm install 16
      nvm use 16
      npm-install-global
      nvm install 18
      nvm use 18
      npm-install-global
      nvm install 20
      nvm alias default 20
      nvm use 20
      npm-install-global
      echo
    fi

    if [ ! -f "$HOME/dev/z/z.sh" ]
    then
      echo "Installing z"
      git clone --depth 1 https://github.com/rupa/z.git ~/dev/z
      . "$HOME/dev/z/z.sh"
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

  if [ ! -d "$HOME/.rbenv/bin" ] && [ ! -s "$(which rbenv)"  ]
  then
    echo "Installing rbenv"
    curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash
    eval "$(rbenv init -)"
  fi

  if [ -z "$(ls -A $HOME/.rbenv/versions/)" ]
  then
    echo "Installing latest ruby version"
    rbenv install $(rbenv install -l | grep -v - | tail -1)
    rbenv global $(rbenv install -l | grep -v - | tail -1)
    echo "Installing React Native ruby version"
    rbenv install 2.7.6
    rbenv global 2.7.6
  fi

  if  [ -s "$(which gem)"  ] && [ ! -n "$(gem list -i "^neovim$")" ]
  then
    _BOOTSTRAP_INSTALL="gem install neovim solargraph --no-document"
    echo "Installing gems:"
    echo "$_BOOTSTRAP_INSTALL"
    echo
    eval "$_BOOTSTRAP_INSTALL"
    echo
  else
    echo "gem not available or neovim already installed. Skipping..."
    echo
  fi

  if [ ! -d "$HOME/.pyenv/bin" ]
  then
    echo "Installing pyenv"
    curl https://pyenv.run | bash
  fi

  if [ ! -s "$(which pyenv)"  ]
  then
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
  fi

  if [ ! -d "$HOME/.pyenv/versions/3.12.2" ]
  then
    echo "Installing python3"
    pyenv install 3.12.2
    pyenv global 3.12.2
    echo "python version: $(python --version)"
    python3 -m pip install --upgrade pip
  fi

  if [ ! -d "$HOME/.pyenv/versions/py3nvim" ]
  then
    echo "Installing py3nvim virtualenv"
    eval "$(pyenv init -)"
    pyenv virtualenv 3.12.2 py3nvim
    pyenv activate py3nvim
    python3 -m pip install --upgrade pip
    python3 -m pip install --upgrade pynvim
    pyenv deactivate
    echo
  fi

  if [ -s "$(which python3)" ]
  then
    echo "Installing idb"
    python3 -m pip install --upgrade fb-idb --prefer-binary
    echo
  else
    echo "python3 not available or idb already installed. Skipping..."
    echo
  fi

  if [ ! -s "$(which pyls)" ]
  then
    echo "Installing python-language-server (pyls)"
    python3 -m pip install --upgrade pyls
  fi

  if [ ! -s "$(which brew)" ]
  then
    echo "Brew not installed. Skipping the rest of the installs"
    exit 0
  fi

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

  if [ ! -s "$(which shellcheck)" ]
  then
    echo "Installing shellcheck"
    brew install shellcheck
    echo
  fi

  JAVA_VERSION=17

  if [ ! -s "$(which java)" ]
  then
    echo "Installing java"
    brew install "zulu@$JAVA_VERSION"
    echo
  fi

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

  if [ ! -n "$(brew list --cask font-fira-code-nerd-font)" ]
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

  if [ ! -s "$(which tmux)"  ]
  then
    echo "Installing tmux"
    brew install tmux
  fi

  brew install git \
    neovim \
    bash-completion \
    zlib \
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
    node@20 \
    renameutils \
    tmux-mem-cpu-load

  brew install --cask \
    homebrew/cask/cmake \
    alacritty \
    iterm2 \
    warp \
    appcleaner \
    steam \
    tunnelblick \
    imageoptim \¢
    vlc \
    grandperspective \
    install-disk-creator \
    geekbench \
    iconjar \
    spectacle \
    google-cloud-sdk \
    graphql-playground \
    sequel-ace \
    firefox \
    1password \
    1password-cli \
    homebrew/cask/docker \
    postman
fi
