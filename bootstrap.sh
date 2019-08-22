#!/bin/bash

# Install all the dotfiles

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
linkFileToHome "tmux-conf" ".tmux.conf"

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
