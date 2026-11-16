#!/usr/bin/env bash
# bootstrap.sh's closing message: what to do after a real run.
#
# Usage: next_steps.sh BREW_BASH DRY_RUN(0|1)
set -euo pipefail

brew_bash="$1"

if [ "$2" = 1 ]; then
  printf '\nDry run complete: mise bootstrap applied nothing.\n'
  exit 0
fi

cat <<'MSG'

Done. Open a new login shell (or: exec $SHELL -l) so mise/gpg-agent/brew/cargo
PATH take effect.
MSG

# These dotfiles configure bash only: zsh (the macOS default) gets no Homebrew
# or mise on PATH, and /bin/bash is 3.2, too old for lib/. Changing the login
# shell needs sudo and the user's password, so it is left to the user.
if [ "$(uname -s)" = Darwin ] && [ "${SHELL:-}" != "$brew_bash" ]; then
  cat <<MSG

Your login shell is ${SHELL:-unset}, but these dotfiles only configure bash.
Switch to Homebrew's bash, then open a new terminal window:
  grep -qx $brew_bash /etc/shells || echo $brew_bash | sudo tee -a /etc/shells
  chsh -s $brew_bash
MSG
fi
