#!/bin/bash

# Source all the files in this directory
function source_lib()
{
  local SOURCE_FILES=($(ls -d "$DOTFILES"/lib/* | grep -v index.sh))
  for file in "${SOURCE_FILES[@]}"
  do
    . "$file"
  done
}

source_lib

# Remove this function from the global scope
unset -f source_lib
unset file
