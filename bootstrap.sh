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

mkdir ~/$HOME/dev/bin

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

# .config/alacritty/alacritty.yml
mkdir -p ~/.config/alacritty
backupFile ".config/alacritty/alacritty.yml"
linkFileToHome "alacritty.yml" ".config/alacritty/alacritty.yml"

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

# Setup ssh-agent
## If agent socket isn't available, source it
[ -s "$SSH_AUTH_SOCK" ] || eval `ssh-agent -s`
## If key hasn't been added to keychain, add it
ssh-add -L > /dev/null || ssh-add -K "$HOME/.ssh/id_rsa" > /dev/null 2>&1 || ssh-add "$HOME/.ssh/id_rsa"

# Install tmux plugins
[ ! -d "$HOME/.tmux/plugins/tpm" ] && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# More rudimentary flags parsing
if [ "$1" = "-i" ] || [ "$1" = "--install-deps" ]
then
  echo "--install-deps detected. Installing dependencies..."
  echo

  . "./scripts/install.sh"

  if   [ $(which curl)  ]
  then

    if   [ ! -f "$HOME/.vim/autoload/plug.vim" ]
    then
      _BOOTSTRAP_INSTALL="curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
      echo "Installing vim-plug:"
      echo "$_BOOTSTRAP_INSTALL"
      echo
      eval "$_BOOTSTRAP_INSTALL"
      echo
    fi

    if   [ $(which nvim)  ] && [ ! -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ]
    then
      _BOOTSTRAP_INSTALL="curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
      echo "Installing vim-plug for neovim:"
      echo "$_BOOTSTRAP_INSTALL"
      echo
      eval "$_BOOTSTRAP_INSTALL"
      echo
    fi

    _BOOTSTRAP_INSTALL="curl https://sh.rustup.rs -sSf | sh -s -- -y"
    echo "Installing rust:"
    echo "$_BOOTSTRAP_INSTALL"
    echo
    eval "$_BOOTSTRAP_INSTALL"
    export PATH="$HOME/.cargo/bin:$PATH"
    [ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
    echo

    _BOOTSTRAP_INSTALL="curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.36.0/install.sh | bash"
    echo "Installing nvm:"
    echo "$_BOOTSTRAP_INSTALL"
    echo
    eval "$_BOOTSTRAP_INSTALL"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh"  ] && . "$NVM_DIR/nvm.sh" # This loads nvm
    echo

    _BOOTSTRAP_INSTALL="nvm install 12"
    echo "Installing node v12:"
    echo "$_BOOTSTRAP_INSTALL"
    echo
    eval "$_BOOTSTRAP_INSTALL"
    echo

    if [ -f "$HOME/dev/z/z.sh" ]
    then
      echo "Installing z"
      git clone --depth 1 https://github.com/rupa/z.git ~/dev/z
      . "$HOME/dev/z/z.sh"
    fi

  else
    echo "ERROR: curl not available! Skipping all installs"
    echo
  fi


  if   [ ! $(which npm)  ]
  then
    _BOOTSTRAP_INSTALL="npm install -g neovim eslint_d"
    echo "Installing global node modules:"
    echo "$_BOOTSTRAP_INSTALL"
    echo
    eval "$_BOOTSTRAP_INSTALL"
  else
    echo "ERROR: npm not available!"
    exit 1
  fi


  if   [ ! $(which gem)  ]
  then
    _BOOTSTRAP_INSTALL="gem install neovim solargraph --no-document"
    echo "Installing gems:"
    echo "$_BOOTSTRAP_INSTALL"
    echo
    eval "$_BOOTSTRAP_INSTALL"
    echo
  else
    echo "ERROR: gem not available! Skipping..."
    echo
  fi

  if   [ $(which brew)  ]
  then
    _BOOTSTRAP_INSTALL="brew tap homebrew/cask-fonts && brew cask install font-firacode-nerd-font font-hack-nerd-font font-fontawesome"
    echo "Installing fonts:"
    echo "$_BOOTSTRAP_INSTALL"
    echo
    eval "$_BOOTSTRAP_INSTALL"
    echo
  else
    echo "ERROR: brew not available! Skipping..."
    echo
  fi
fi
