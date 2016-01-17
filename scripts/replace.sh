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

  usage='Usage: replace OLDPATTERN NEWPATTERN

Example:
  replace '"'"'original'"'"' '"'"'replacewith'"'"'
  replace '"'"'old\\\\/path\\\\.js'"'"' '"'"'new\\\\/path\\\\.jsx'"'"'
'

  # Return usage if not 2 args are passed
  if [ $# -ne 2 ]
  then
    echo -e "$usage"
    return 1
  fi

  git grep --untracked -I -l "$1" \
    | xargs sed -i '' -e ''s/"$1"/"$2"/g''
}

