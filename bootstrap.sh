#!/bin/bash

# Install all the dotfiles

# Get bootstrap script directory
THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )

# Backup existing files and replace with symlinks
files=( 
  ".bash_profile"
  ".vimrc"
  ".gitconfig"
)
for file in "${files[@]}"; do
	if [ -e ~/$file -a ! -L ~/$file ]; then
		mv ~/$file ~/${file}.backup
	fi
	ln -sf ${THIS_DIR}/${file} ~/${file}
done

