# CLAUDE.md

## Rules

1. **Beads issue references**: `dotfiles-*` (e.g. `dotfiles-6x9`) are beads issue keys — look them up with `bd show <id>`
2. **Bead lifecycle during superpowers skills**: When any superpowers skill (brainstorming, design, planning, or execution) is invoked for a bead, immediately run `bd update <id> --status=in_progress`. If execution does not complete before the agent stops, run `bd update <id> --status=ready` to reset it.
3. **After making any changes, run tests**: `just test-unit` first, then `just test`
4. **Bug fixes require tests**: see [docs/testing.md](docs/testing.md) for policy
5. **Bash syntax checking**: use `bashcheck` — never `bash -n`
6. **Git commits**: single-line only with `git commit -m "..."`, no heredoc, no Co-Authored-By

## Key Commands

```bash
./bootstrap.sh      # Initial setup (symlinks + optional deps with -i flag)
just test-unit      # Fast bash unit tests (bats-core, no Docker)
just test           # Full test suite in Docker
```

## Context Index

- Architecture, entry points, mise, environment config → [docs/architecture.md](docs/architecture.md)
- Patterns, workflows, aliases, common commands → [docs/patterns.md](docs/patterns.md)
- Testing policy and bug fix guidance → [docs/testing.md](docs/testing.md)
