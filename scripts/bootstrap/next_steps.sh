#!/usr/bin/env bash
# bootstrap.sh's closing message: what to do after a real run, including a
# numbered list of manual follow-ups that bootstrap cannot or should not do.
#
# To add a follow-up, call `todo` below with its text: the first line is the
# item and the rest print indented under it; indent commands and paths two
# spaces in the text to set them apart from the prose.
#
# Usage: next_steps.sh BREW_BASH DRY_RUN(0|1)
set -euo pipefail

brew_bash="$1"

if [ "$2" = 1 ]; then
  printf '\nDry run complete: mise bootstrap applied nothing.\n'
  exit 0
fi

todos=()
todo() { todos+=("$1"); }

new_window=0
if [ "$(uname -s)" = Darwin ]; then
  # These dotfiles configure bash only: zsh (the macOS default) gets no
  # Homebrew or mise on PATH, and /bin/bash is 3.2, too old for lib/. Changing
  # the login shell needs sudo and the user's password, so it is left to the user.
  if [ "${SHELL:-}" != "$brew_bash" ]; then
    new_window=1
    todo "Your login shell is ${SHELL:-unset}, but these dotfiles only configure bash.
Switch to Homebrew's bash, then open a new terminal window:
  grep -qx $brew_bash /etc/shells || echo $brew_bash | sudo tee -a /etc/shells
  chsh -s $brew_bash"
  fi

  # Scripting Spotlight's Search Privacy list means editing a root-only plist,
  # which needs Full Disk Access for the terminal; we don't ask for that.
  todo "Keep Spotlight from indexing build output and caches: System Settings >
Spotlight > Search Privacy, click +, press Cmd-Shift-G to type each path
(skip any that don't exist yet):
  ~/dev
  ~/Library/Developer/Xcode/DerivedData
  ~/Library/Developer/Xcode/iOS DeviceSupport
  ~/Library/Developer/CoreSimulator
  ~/Library/Caches
  /opt/homebrew"
fi

echo
if [ "$new_window" = 1 ]; then
  echo "Done."
else
  echo "Done. Open a new login shell (or: exec \$SHELL -l) so mise/brew/cargo"
  echo "PATH take effect."
fi

[ "${#todos[@]}" -gt 0 ] || exit 0

printf '\nManual follow-ups:\n'
n=0
for item in "${todos[@]}"; do
  n=$((n + 1))
  # The first line is the numbered item; the rest continue it, indented.
  first=1
  while IFS= read -r line; do
    if [ "$first" = 1 ]; then
      printf '\n%d. %s\n' "$n" "$line"
      first=0
    else
      printf '   %s\n' "$line"
    fi
  done <<<"$item"
done
