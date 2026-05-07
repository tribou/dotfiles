# Bootstrap.sh: Run cleanly in non-tmux sessions

**Issue:** dotfiles-exk
**Date:** 2026-05-06

## Problem

`bootstrap.sh` aborts midway when run from a plain (non-tmux) shell. The last
output before exit is:

```
no server running on /tmp/tmux-1001/default
```

This regressed in commit `fa49d33`, which replaced a single-line tpm invocation
with a block that calls `tmux start-server` and then `tmux set-environment -g`.
`tmux start-server` does not keep the server alive between command invocations:
when the command exits with no clients or sessions present, the server exits
with it. The next `tmux` call therefore connects to a dead/missing server and
fails with "no server running". Under `set -euo pipefail` the whole script
aborts.

tpm's `install_plugins` reads `TMUX_PLUGIN_MANAGER_PATH` via
`tmux show-option -gqv`, so a live server with that global env set is in fact
required — we can't simply drop the tmux calls.

## Fix

Anchor the work in an ephemeral detached session when not already inside tmux;
reuse the existing server when `$TMUX` is set.

```bash
[ ! -d "$HOME/.tmux/plugins/tpm" ] && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
if command -v tmux &> /dev/null; then
  if [ -n "${TMUX:-}" ]; then
    tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins/"
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true
  else
    tmux new-session -d -s _bootstrap_tpm
    tmux set-environment -t _bootstrap_tpm -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins/"
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true
    tmux kill-session -t _bootstrap_tpm 2>/dev/null || true
  fi
fi
```

`new-session -d` keeps the server alive for the duration of the install because
the detached session is itself a client-less but persistent attachment. We
clean up the temporary session afterwards.

## Test (TDD)

Per the project's bug-fix policy, add a failing structural test in
`tests/bootstrap.bats` first:

- Assert the tmux block contains `tmux new-session -d` (the anchor that fixes
  the regression). Matches the structural-grep style of the existing tests.

## Scope

Two files:

- `bootstrap.sh` — replace lines 182–186 with the guarded block above.
- `tests/bootstrap.bats` — add one test.

No other files touched.

## Out of scope

- Refactoring or restructuring the rest of `bootstrap.sh`.
- Caching or skipping tpm install based on plugin state — orthogonal to this
  bug.
