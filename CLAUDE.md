# CLAUDE.md

## Rules

1. **Beads issue references**: `dotfiles-*` (e.g. `dotfiles-6x9`) are beads issue keys — look them up with `bd show <id>`
2. **After making any changes, run tests**: `just test-unit` first, then `just test`
3. **Bug fixes require tests**: see [docs/testing.md](docs/testing.md) for policy
4. **Bash syntax checking**: use `bashcheck` — never `bash -n`
5. **Git commits**: single-line only with `git commit -m "..."`, no heredoc, no Co-Authored-By
6. **Creating new skills**: use `superpowers:writing-skills` skill

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
- Custom AI skills (Claude Code + opencode) → `skills/`
