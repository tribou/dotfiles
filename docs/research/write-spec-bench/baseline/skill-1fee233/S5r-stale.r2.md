# Split lib/commands.sh into focused modules

## Problem
`lib/commands.sh` mixes unrelated domains: git, npm, docker, tmux, AWS, DigitalOcean, terraform, SSH, and general shell utilities. The file can't be tested in isolation, is hard to review, and causes merge conflicts when separate concerns change.

## Evidence
- Under `en_US.UTF-8`, `ls`/glob ordering sorts `_shared.sh` 10th of 11, not first (issue #153, 2026-07-06; recheck).
- `lib/index.sh` appears to source `lib/*.sh` dynamically, excluding `index.sh` (issue body; recheck).
- Repo-scaffolding code is near L712–745 (`.gitignore` generator). The Claude keep-alive loop is near L375–388 (issue body; line numbers may have drifted).

## Outcome
`lib/commands.sh` holds only general shell utilities. Each other domain lives in its own module under `lib/`, following the boundary, size, naming, and load-order rules in #153.

## Acceptance
- `just test-unit` and `just test` pass.
- In a new shell session, all existing aliases and functions still work.
- No `lib/*.sh` file exceeds ~300 lines (`wc -l`).
- `_shared.sh` is sourced before every non-underscore module.
- `bashcheck` passes on each new file.

## Bounds
- No changes to function signatures or alias names; this is a file reorganization only.
- No pre-splitting of the small terraform and ssh pieces.

## Decisions
- Land first: `lib/index.sh` sources `_*.sh` files first and explicitly, with a test for that ordering.
- `lib/repo.sh` holds the `.gitignore` generator and `mkrepo`. They must not end up in `lib/commands.sh`.
- `lib/agent.sh` holds the Claude keep-alive loop and related helpers.
- `lib/cloud.sh` holds AWS, DigitalOcean, terraform, and SSH cloud helpers as one file. It splits by tool only when it nears the ~300-line cap (#153).
- `lib/commands.sh` keeps only what fits no other module.

## References
- #153 (dotfiles lib module organization convention)
- Migrated from beads issue dotfiles-dtk

Suggested: `lib/git.sh`, `lib/npm.sh`, `lib/docker.sh`, and `lib/tmux.sh` for the git, npm/node, docker, and tmux code.
