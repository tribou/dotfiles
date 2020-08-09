#!/bin/bash -l

# Print helpful commands that can be grepped
function command_reference()
{
  read -r -d '' REFERENCE_MESSAGE << EOF
android: adb reverse tcp:8081 tcp:8081
android: adb shell input keyevent 82
android: adb uninstall com.package
android: ./gradlew assembleRelease --console plain
awk: awk '{print \$1 " \\\\"}'  # Add single backslash (\\) to each line
docker: docker-machine create --driver google --google-machine-type n1-standard-1 --google-zone us-central1-b --google-disk-size 40 --google-disk-type pd-ssd --google-project GOOGLE_PROJECT_ID --google-machine-image=https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts tribou-dev
git: git rebase --onto newbase oldbase branch-to-move
imagemagick: convert -resize 50% logo@2x.png logo.png
images: app-icon generate --platforms=ios
images: sips -s format png yeti-icon.icns --out yeti-icon.png
rename: rename 's/_/-/' static/images/slides/*
ssh: ssh-keygen -R 159.200.81.180
ssh: ssh-keygen -t rsa -b 4096 -C "tribou@users.noreply.github.com"
system: sudo lsof -inP | grep TCP
system: sudo lsof -i :8081
typescript: npx dts-gen -m module-name
EOF

  _dotfiles_display_reference "$REFERENCE_MESSAGE" "$1"
}

function _dotfiles_display_reference()
{
  local REFERENCE_MESSAGE="$1"

  if [ $# -ne 2 ]
  then
    local GREP_STRING="."
  else
    local GREP_STRING="$2"
  fi

  # Text coloring helpers
  local RESET=`tput sgr0`
  local DARK_GRAY=`tput setaf 0`

  # Format it nicely
  echo "$REFERENCE_MESSAGE" \
    | grep "$GREP_STRING" \
    | awk -F ': ' '{ printf DARK_GRAY; printf("%30s:",$1); printf RESET; $1 = ""; print $0 }' \
    "RESET=${RESET}" \
    "DARK_GRAY=${DARK_GRAY}" \
    | fzf +s --tac --ansi -m | cat
}

alias cmdref="command_reference"
alias ref="command_reference"

function vim_reference() {
  read -r -d '' REFERENCE_MESSAGE << EOF
  location list: lopen
  location list: lclose
  location list: lnext
  location list: prev
  location list: ll
  location list: lf <file>
  quickfix: copen
  quickfix: cclose
  quickfix: cnext
  quickfix: cprev
  quickfix: cc
  quickfix: cf <file>
  window navigation: <c-w> hjkl
  window new split: <c-w> n
  window new split: new
  window new vertical split: vne[w]
  window split: <c-w> s
  window split: sp[lit]
  window vertical split: <c-w> v
  window vertical split: vsp[lit]
EOF

  _dotfiles_display_reference "$REFERENCE_MESSAGE" "$1"
}

alias vimref="vim_reference"
