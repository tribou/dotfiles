#!/bin/bash

# Install all the dotfiles

# Get bootstrap script directory
THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )

# Backup existing files and replace with symlinks
files=( 
  ".bash_profile"
  ".vimrc"
  ".gitconfig"
  ".zshrc"
)
for file in "${files[@]}"; do
	if [ -e ~/$file -a ! -L ~/$file ]; then
    echo "Backing up ${file}"
		mv ~/$file ~/${file}.backup
  fi
  echo "Creating a symlink for ${file}"
	ln -sf ${THIS_DIR}/${file} ~/${file}
done

