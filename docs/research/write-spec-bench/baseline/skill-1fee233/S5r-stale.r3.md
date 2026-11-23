# Split lib/commands.sh into focused domain modules

## Problem
`lib/commands.sh` mixes unrelated domains: git, npm, docker, tmux, AWS, DigitalOcean, terraform, SSH, and general shell utilities. It can't be tested in isolation and is hard to review. Unrelated changes cause merge conflicts.

## Evidence
- `lib/index.sh` appears to source `lib/*.sh` by glob, excluding `index.sh`, so new files load automatically (issue body; recheck).
- Under `en_US.UTF-8`, glob/`ls` ordering appears to sort `_shared.sh` 10th of 11, not first (#153; recheck). A new source-time dependency on `_shared.sh` could then break silently.

## Outcome
Each domain lives in its own module, and `lib/commands.sh` holds only general shell utilities. `_shared.sh` loads before every non-underscore module.

## Acceptance
- `lib/index.sh` sources `_*.sh` files first, explicitly, with a test covering the order. This lands before the split.
- All existing aliases and functions work in a new shell session.
- No `lib/*.sh` file exceeds the ~300-line soft cap from #153.
- `just test-unit` and `just test` pass.

## Bounds
- No changes to function signatures or alias names.
- No pre-splitting of the small terraform and ssh pieces.

## Decisions
- Follow #153 for boundaries, size, naming, and load order.
- Modules: `lib/git.sh`, `lib/npm.sh`, `lib/docker.sh`, `lib/tmux.sh`, `lib/cloud.sh`, `lib/repo.sh`, `lib/agent.sh`.
- `lib/cloud.sh` holds AWS, DigitalOcean, terraform, and SSH in one file. Split by tool only once it nears the ~300-line cap.
- `lib/repo.sh` holds the `.gitignore` generator and `mkrepo`; they must not land in `lib/commands.sh`.
- `lib/agent.sh` holds the Claude keep-alive loop and related helpers.
- `lib/commands.sh` keeps only what fits no other module.
- Lint each new file with `bashcheck`, not `bash -n`.

## References
- #153 (lib module organization convention)
- Migrated from beads issue dotfiles-dtk.
