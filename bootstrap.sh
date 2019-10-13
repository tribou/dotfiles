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

# setup API keys file
if [ ! -f "$HOME/.ssh/api_keys" ]
then
  touch "$HOME/.ssh/api_keys"
fi

# More rudimentary flags parsing
if [ "$1" = "-i" ] || [ "$1" = "--install-deps" ]
then
  echo "--install-deps detected. Installing dependencies..."
  echo

  if   [ -s "$(which curl)"  ]
  then
    _BOOTSTRAP_INSTALL="curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    echo "Installing vim-plug:"
    echo "$_BOOTSTRAP_INSTALL"
    echo
    eval "$_BOOTSTRAP_INSTALL"

    echo

    if   [ -s "$(which nvim)"  ]
    then
      _BOOTSTRAP_INSTALL="curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
      echo "Installing vim-plug for neovim:"
      echo "$_BOOTSTRAP_INSTALL"
      echo
      eval "$_BOOTSTRAP_INSTALL"

      echo
    fi

    _BOOTSTRAP_INSTALL="curl https://sh.rustup.rs -sSf | sh"
    echo "Installing rust:"
    echo "$_BOOTSTRAP_INSTALL"
    echo
    eval "$_BOOTSTRAP_INSTALL"
    export PATH="$HOME/.cargo/bin:$PATH"
    [ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

    echo

    _BOOTSTRAP_INSTALL="curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh | bash"
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

    if   [ -s "$(which make)"  ]
    then
      _BOOTSTRAP_INSTALL="rm -rf /tmp/fasd && git clone https://github.com/clvv/fasd.git /tmp/fasd && cd /tmp/fasd && make install && cd $THIS_DIR && rm -rf /tmp/fasd"
      echo "Installing fasd:"
      echo "$_BOOTSTRAP_INSTALL"
      echo
      eval "$_BOOTSTRAP_INSTALL"
      [ $(which fasd) ] && eval "$(fasd --init bash-hook)"

      echo
    fi
  else
    echo "ERROR: make not available! Skipping fasd install..."
    echo
  fi


  if   [ -s "$(which npm)"  ]
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


  if   [ -s "$(which gem)"  ]
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
fi
