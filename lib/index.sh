#!/bin/bash

# Source shared modules first, then domain modules.
function source_lib()
{
  local file
  for file in "$DOTFILES"/lib/_*.sh "$DOTFILES"/lib/[!_]*.sh
  do
    [ -f "$file" ] || continue
    [ "$file" = "$DOTFILES/lib/index.sh" ] && continue
    . "$file"
  done
}

source_lib

# Remove this function from the global scope
unset -f source_lib
