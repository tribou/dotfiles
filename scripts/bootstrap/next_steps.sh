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
fi

# converge.sh generates SSH keys but can't register them with GitHub. BatchMode
# keeps ssh from prompting; accept-new records GitHub's host key on first use,
# as the first git-over-ssh would. ssh -T exits 1 even on success, so only
# GitHub's greeting tells whether the key is registered.
github="$(ssh -T -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new \
  git@github.com 2>&1 || true)"
if [[ "$github" != *"successfully authenticated"* ]]; then
  todo "Add this machine's SSH key to GitHub so git@github.com remotes work:
  gh auth login --scopes admin:public_key
  gh ssh-key add ~/.ssh/id_ed25519.pub --title \"\$(hostname)\""
fi

# A GPG key needs a passphrase, so bootstrap leaves creating one to the user.
# Only an active secret key counts: an expired or revoked one can't sign. In
# --with-colons output, field 12 lists usable capabilities in capitals, and gpg
# drops them for expired or revoked keys, so a usable key shows an S there.
if ! gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '$1 == "sec" && $12 ~ /S/ { found = 1 } END { exit !found }'; then
  todo "Create a GPG key and add it to GitHub so signed commits show as verified:
  gpg --quick-generate-key \"\$(git config user.name) <\$(git config user.email)>\" ed25519 sign 2y
  gh auth refresh --scopes write:gpg_key
  gpg --armor --export \"\$(git config user.email)\" | gh gpg-key add --title \"\$(hostname)\" -"
fi

# spotlight_may_index DIR: false only when Spotlight provably skips DIR: it
# holds a file older than a day (time for Spotlight to have caught up) that
# `mdfind -onlyin` can't find. Excluded and otherwise unindexed folders both
# count as done, since the goal is that Spotlight leaves them alone. A folder
# with no such file, or an mdfind error, can't be judged, so it stays listed.
spotlight_may_index() {
  local file hits
  file="$(find "$1" -maxdepth 3 -name '.*' -prune -o -type f -mtime +0 -print -quit 2>/dev/null || true)"
  [ -n "$file" ] || return 0
  hits="$(mdfind -onlyin "$1" -name "$(basename "$file")" 2>/dev/null)" || return 0
  [ -n "$hits" ]
}

if [ "$(uname -s)" = Darwin ]; then
  # The quick terminal's global: keybind (ghostty/config.ghostty) needs this.
  # AXIsProcessTrusted() answers for the app that started this process, so it
  # tells us about Ghostty only when bootstrap runs in Ghostty (and not inside
  # tmux, which replaces TERM_PROGRAM); anywhere else the item stays listed.
  if [ "${TERM_PROGRAM:-}" != ghostty ] ||
    [ "$(osascript -l JavaScript -e 'ObjC.import("ApplicationServices"); $.AXIsProcessTrusted()' 2>/dev/null || true)" != true ]; then
    todo "Let Ghostty's quick terminal (ctrl+alt+\`) open from any app: System Settings >
Privacy & Security > Accessibility, turn on Ghostty (open Ghostty once first)."
  fi

  # Scripting Spotlight's Search Privacy list means editing a root-only plist,
  # which needs Full Disk Access for the terminal; we don't ask for that, so
  # list each folder that exists and Spotlight may still be indexing.
  spotlight_paths=()
  # The quoted ~ is meant: it's what the user types, and expanded below.
  # shellcheck disable=SC2088
  for path in '~/dev' '~/Library/Developer/Xcode/DerivedData' \
    '~/Library/Developer/Xcode/iOS DeviceSupport' '~/Library/Developer/CoreSimulator' \
    '~/Library/Caches' "${brew_bash%/bin/bash}"; do
    dir="${path/#\~/$HOME}"
    if [ -d "$dir" ] && spotlight_may_index "$dir"; then
      spotlight_paths+=("  $path")
    fi
  done
  if [ "${#spotlight_paths[@]}" -gt 0 ]; then
    todo "Keep Spotlight from indexing build output and caches: System Settings >
Spotlight > Search Privacy, click +, press Cmd-Shift-G to type each path:
$(printf '%s\n' "${spotlight_paths[@]}")"
  fi
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
