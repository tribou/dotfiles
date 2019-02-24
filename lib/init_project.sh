#!/bin/bash -l

# Create boilerplate files for most new projects

function init() {

  usage='Usage: init'
  target_dir='.'
  YEAR=$(date +%Y)

  # Return error if DOTFILES env var is not set
  if [ -z $DOTFILES ]
  then
    echo "DOTFILES env var is not set"
    return 1
  fi

  # Return usage if args are passed
  if [ $# -gt 0 ]
  then
    echo "$usage"
    return 1
  fi

  template_dir=$DOTFILES/templates/init

  # SCM info
  PS3='Which SCM? '
  options=('GitHub' 'Bitbucket' 'Quit')
  select opt in "${options[@]}"
  do
    case $opt in
      "GitHub")
        SCM_NAME='github'
        SCM_HOST='github.com'
        break
        ;;
      "Bitbucket")
        SCM_NAME='bitbucket'
        SCM_HOST='bitbucket.org'
        break
        ;;
      "Quit")
        echo
        echo "bye 👋"
        return
        ;;
      *) echo invalid option;;
    esac
  done
  echo

  # Project Name
  current_dir=$(echo "$PWD" | sed 's/^.*\///')
  PS3='Project Name? '
  options=("${current_dir}" 'Other' 'Quit')
  select opt in "${options[@]}"
  do
    case $opt in
      "$current_dir")
        PROJECT_NAME="$current_dir"
        break
        ;;
      "Other")
        echo
        echo "What's the project name?"
        read PROJECT_NAME
        break
        ;;
      "Quit")
        echo
        echo "bye 👋"
        return
        ;;
      *) echo invalid option;;
    esac
  done
  echo

  # Org Name
  PS3='Org Name/Repo Owner? '
  options=('tribou' 'Other' 'Quit')
  select opt in "${options[@]}"
  do
    case $opt in
      "tribou")
        ORG_NAME='tribou'
        break
        ;;
      "Other")
        echo
        echo "What's the org/repo owner name?"
        read ORG_NAME
        break
        ;;
      "Quit")
        echo
        echo "bye 👋"
        return
        ;;
      *) echo invalid option;;
    esac
  done

  echo
  echo "SCM Host:  $SCM_HOST"
  echo "SCM Name:  $SCM_NAME"
  echo "Project:   $PROJECT_NAME"
  echo "Org/Owner: $ORG_NAME"
  echo

  # Copy over templates
  cp -Rn $template_dir/* $target_dir

  # Replace vars in templates
  templates=$(find "$target_dir" \
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
    )
  for file in "$templates"
  do

    sed -i '' -e ''s/\{\{SCM_HOST\}\}/"$SCM_HOST"/g'' $file
    sed -i '' -e ''s/\{\{SCM_NAME\}\}/"$SCM_NAME"/g'' $file
    sed -i '' -e ''s/\{\{PROJECT_NAME\}\}/"$PROJECT_NAME"/g'' $file
    sed -i '' -e ''s/\{\{ORG_NAME\}\}/"$ORG_NAME"/g'' $file
    sed -i '' -e ''s/\{yyyy\}/"$YEAR"/g'' $file
    sed -i '' -e ''s/\{name.of.copyright.owner\}/"$ORG_NAME"/g'' $file

  done

  if [ ! -d .git ]
  then

    git init
    echo

  fi

  if [ -n "$(which yarn)" ]
  then

    yarn

  fi

  git add --all

  echo
  echo "🚀  Project's ready for launch!"

}
