*Global rules, command reference, and index to all project context — the only file AI agents need to open first*

# CRITICAL Rules

1. **Git commits**: single-line only with `git commit -m "..."`, no Co-Authored-By
2. **Bash syntax checking**: use `bashcheck` — never `bash -n`
3. **After making any changes, run tests**: `just test-unit` first, then `just test`
4. **Bug fixes require tests**: see `docs/TESTING.md` for policy
5. **Creating new skills**: use `superpowers:writing-skills` skill

## Additional Rules

1. **Beads issue references**: `dotfiles-*` (e.g. `dotfiles-6x9`) are beads issue keys — look them up with `bd show <id>`
2. **Bead lifecycle during superpowers skills**: When any superpowers skill (brainstorming, design, planning, or execution) is invoked for a bead, immediately run `bd update <id> --status=in_progress`. If execution does not complete before the agent stops, run `bd update <id> --status=ready` to reset it.

## Key Commands

```bash
./bootstrap.sh      # Initial setup (symlinks + optional deps with -i flag)
just test-unit      # Fast bash unit tests (bats-core, no Docker)
just test           # Full test suite in Docker
```

## Context Index

- Architecture, entry points, mise, environment config → [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Development, naming conventions, design principles, patterns, workflows, aliases, common commands → [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)
- Product and domain context → [docs/PRODUCT.md](docs/PRODUCT.md)
- Security policies and secrets → [docs/SECURITY.md](docs/SECURITY.md)
- Testing policy and bug fix guidance → [docs/TESTING.md](docs/TESTING.md)
- Non-interactive shell safety flags → [AGENTS.md](AGENTS.md)
- Custom AI skills (Claude Code + opencode) → `skills/`
