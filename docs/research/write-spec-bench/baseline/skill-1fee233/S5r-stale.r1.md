# Split lib/commands.sh into focused domain modules

## Problem
`lib/commands.sh` mixes unrelated domains: git, npm, docker, tmux, AWS, DigitalOcean, terraform, SSH, and general shell utilities. It can't be tested in isolation, is hard to review, and causes merge conflicts when separate concerns change.

## Evidence
- `lib/commands.sh` was 1,384 lines, 61 functions, 135 aliases when filed (recheck with `wc -l`).
- Under `en_US.UTF-8`, `ls`/glob ordering reportedly sorts `_shared.sh` 10th of 11, not first (recheck). A source-time dependency on `_shared.sh` could break silently.

## Outcome
`lib/commands.sh` holds only general shell utilities. Each domain lives in its own `lib/*.sh` module that follows the #153 conventions for boundaries, size, naming, and load order.

## Acceptance
- `just test-unit` and `just test` pass.
- All existing aliases and functions work in a new shell session, with no signature or alias-name changes.
- No `lib/*.sh` file is over ~300 lines (soft cap per #153).
- `_shared.sh` is sourced before every non-underscore module.
- `bashcheck` passes on each new file.

## Bounds
- No changes to function signatures or alias names.
- Don't pre-split the small terraform/ssh pieces in `cloud.sh`.

## Decisions
- Before splitting, make `lib/index.sh` source `_*.sh` files first, explicitly. Land this with its test first.
- `lib/repo.sh` holds the `.gitignore` generator and `mkrepo`; they must not stay in `lib/commands.sh`.
- `lib/agent.sh` holds the Claude keep-alive loop and related helpers.
- `lib/cloud.sh` holds AWS, DigitalOcean, terraform, and SSH cloud helpers. It stays one file until it nears the ~300-line cap, then splits by tool.
- `bashcheck` is the project linter, not `bash -n`.

## References
- #153 (dotfiles lib module organization convention)
- Migrated from beads issue dotfiles-dtk.

Suggested: `lib/git.sh`, `lib/npm.sh`, `lib/docker.sh`, and `lib/tmux.sh` for the remaining domains.
