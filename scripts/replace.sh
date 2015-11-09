#!/bin/bash -l

# Recursively performs a perl replace on files in current or specified directory

replace() {

  usage='Usage: replace PATTERN [directory]'
  search_dir='.'

  # Return usage if 0 or more than 2 args are passed
  if [ $# -eq 0 ] || [ $# -gt 2 ]
  then
    echo "$usage"
    return 1
  fi

  # Optional second arg
  if [ $# -eq 2 ]
  then
    # Remove trailing slash if any
    search_dir=`echo "$2" | sed 's/\/$//'`
  fi

  find \
    "$search_dir" \
    -type f \
    ! -name "bundle*.js" \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/.svn/*" \
    -exec perl -p -i -e "$1" {} \;

}

