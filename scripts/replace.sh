#!/bin/bash -l

# Recursively performs a perl replace on files in current or specified directory

# But first a convenience function that just finds all the files
findfiles() {

  usage='Usage: findfiles [directory]'
  search_dir='.'

  # Return usage if more than 1 arg is passed
  if [ $# -gt 1 ]
  then
    echo "$usage"
    return 1
  fi

  # Optional first arg
  if [ $# -eq 1 ]
  then
    # Remove trailing slash if any
    search_dir=`echo "$1" | sed 's/\/$//'`
  fi

  find \
    "$search_dir" \
    -type f \
    ! -name "*.log" \
    ! -name "bundle*.js" \
    ! -name "coverage.html" \
    ! -path "*/bower_components/*" \
    ! -path "*/dist/*" \
    ! -path "*/node_modules/*" \
    ! -path "*/tmp/*" \
    ! -path "*/.git/*" \
    ! -path "*/.tmp/*" \
    ! -path "*/.svn/*"

}


replace() {

  usage='Usage: replace PATTERN

Example:
  replace '"'"'s/original/replacewith/g'"'"'
'
  search_dir='.'
  replace_pattern=( $( echo $1 | awk -F '/' '{print $1,$2,$3,$4}') )

  # Return usage if 0 or more than 1 args are passed
  if [ $# -eq 0 ] || [ $# -gt 1 ]
  then
    echo -e "$usage"
    return 1
  fi

  # Make sure PATTERN has three slashes
  num_slashes=$(grep -o "/" <<< "$1" | wc -l | xargs)
  if [ $num_slashes -ne 3 ]
  then
    echo "$usage"
    return 1
  fi

  git grep --untracked -I -l "${replace_pattern[1]}" \
    | xargs sed -i '' -e ''"$1"''

  # find \
  #   "$search_dir" \
  #   -type f \
  #   ! -name "bundle*.js" \
  #   ! -path "*/node_modules/*" \
  #   ! -path "*/.git/*" \
  #   ! -path "*/.svn/*" \
  #   -exec perl -p -i -e "$1" {} \;

}

