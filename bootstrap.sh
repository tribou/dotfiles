#!/bin/bash

# Install all the dotfiles

# Get bootstrap script directory
THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )

function backupFile ()
{
  file=$1

	if [ -e ~/$file -a ! -L ~/$file ]; then
    echo "Backing up ${file}"
		mv ~/$file ~/${file}.backup
  fi
}

function linkFileToHome ()
{
  echo "Creating a symlink for ${1}"
  ln -sf ${THIS_DIR}/${1} ~/${1}
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
linkFileToHome ".bash_profile"

# .vimrc
backupFile ".vimrc"
linkFileToHome ".vimrc"

# .gitconfig
backupFile ".gitconfig"
linkFileToHome ".gitconfig"

# .zshrc
backupFile ".zshrc"
linkFileToHome ".zshrc"

# .config/nvim/init.vim
# Exceptional Case: need to link to the same .vimrc for nvim
mkdir -p ~/.config/nvim
backupFile ".config/nvim/init.vim"
echo "Creating a symlink for .config/nvim/init.vim"
ln -sf ${THIS_DIR}/.vimrc ~/.config/nvim/init.vim

# setup API keys file
if [ ! -f "$HOME/.ssh/api_keys" ]
then
  touch "$HOME/.ssh/api_keys"
fi
