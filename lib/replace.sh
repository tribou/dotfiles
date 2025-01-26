#!/bin/bash -l

# Recursively performs a perl replace on files in current or specified directory

# But first a convenience function that just finds all the files
findfiles() {

  local usage='Usage: findfiles [directory]'
  local search_dir='.'

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
    local search_dir=`echo "$1" | sed 's/\/$//'`
  fi

  find "$search_dir" \
    -type f \
    ! -name "*.log" \
    ! -name "bundle*.js" \
    ! -name "coverage.html" \
    ! -path "*/bin/*" \
    ! -path "*/bower_components/*" \
    ! -path "*/dist/*" \
    ! -path "*/flow-typed/*" \
    ! -path "*/node_modules/*" \
    ! -path "*/tmp/*" \
    ! -path "*/.git/*" \
    ! -path "*/.tmp/*" \
    ! -path "*/.svn/*"

}


replace() {

  local usage='Usage: replace OLDPATTERN NEWPATTERN [directory]

Examples:
  replace '"'"'original'"'"' '"'"'replacewith'"'"'
  replace '"'"'old\\/path\\.js'"'"' '"'"'new\\/path\\.jsx'"'"'
  replace '"'"'original'"'"' '"'"'replacewith'"'"' '"'"'./src/*'"'"'
'

  local search_dir='./*'

  # Return usage if not 2 args are passed
  if [ $# -lt 2 ]
  then
    echo -e "$usage"
    return 1
  fi

  if [ $# -gt 3 ]
  then
    echo -e "$usage"
    return 1
  fi

  if [ $# -eq 3 ]
  then
    local search_dir="$3"
  fi

  git grep --untracked -I -l "$1" -- \
    "$search_dir" \
    ':!build/**' \
    ':!bin/**' \
    ':!flow-typed/**' \
    ':!public/**' \
    ':!vendor/**' \
    ':!*.lock' \
    ':!pnpm-lock.yaml' \
    ':!package-lock.json' \
    | xargs sed -i '' -e ''s/"$1"/"$2"/g''
}

# "Write" complement to ripgrep (rg --replace)
# rg something --replace else           # verify substitutions
# rg something --replace else --stats   # verify total count
# wrg something --replace else          # actually write the changes
function wrg()
{
  local usage='Usage: wrg OLDPATTERN --replace NEWPATTERN

Examples:
  rg something --replace else           # verify substitutions
  rg something --replace else --stats   # verify total count
  wrg something --replace else          # actually write the changes
'

  # Return usage if not 2 args are passed
  if [ $# -eq 0 ]
  then
    echo -e "$usage"
    return 1
  fi

  local seenReplace=''

  for arg in "$@"; do
    if test "$arg" == '--replace' -o "$arg" == '-r'; then
      local seenReplace='true'
      break
    fi
  done

  if test -z "$seenReplace"; then
    echo 'You must specify the --replace or -r argument!'
    return 1
  fi

  local currentFile=''
  local didChange=''

  (
    rg \
      --context 999999 \
      --with-filename --heading --null \
      --color=never --no-line-number \
      --max-columns=0 \
      "$@"
    echo -e '\n\0'
  ) |
  {
    while IFS= read -r -d '' part; do
      if test -n "$currentFile"; then
        echo "$currentFile"
        (sed '$d' | sed '$d') <<< "$part" > "$currentFile"
        local didChange='true'
      fi
      local currentFile="$(tail -n 1 <<< "$part")"
    done

    if test -z "$didChange"; then
      echo "No files were changed."
      return 1
    fi
  }
}
