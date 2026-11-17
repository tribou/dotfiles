#!/bin/bash

# Usage: sizes [PATH...]
function sizes ()
{
  local -a SIZES_PATHS
  if [ $# -eq 0 ]
  then
    SIZES_PATHS=(*)
  elif [ $# -gt 1 ]
  then
    SIZES_PATHS=("$@")
  elif [[ $1 == *\* ]]
  then
    # A quoted glob: expand it here without splitting on spaces
    local IFS=
    # shellcheck disable=SC2206
    SIZES_PATHS=($1)
  elif [ -d "$1" ]
  then
    # Directory: measure each of its entries
    SIZES_PATHS=("${1%/}"/*)
  else
    SIZES_PATHS=("$1")
  fi

  du -sh -- "${SIZES_PATHS[@]}"
}
