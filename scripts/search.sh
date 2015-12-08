#!/bin/bash -l

# Recursively greps files for pattern match

search() {

  usage='Usage: search PATTERN [directory]'
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

  grep \
    -rn "$search_dir" \
    -e "$1" \
    --exclude-dir={.git,.svn,node_modules} \
    --exclude={bundle*.js,coverage.html} \
    --color

}

