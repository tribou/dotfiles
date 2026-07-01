*Global rules, command reference, and index to all project context — the only file AI agents need to open first*

# CRITICAL Rules

1. **Git commits**: single-line only with `git commit -m "..."`, no Co-Authored-By
2. **Bash syntax checking**: use `bashcheck` — never `bash -n`
3. **After making any changes, run tests**: `just test-unit` first, then `just test`
 4. **Bug fixes require TDD tests**: write a failing test first that reproduces the bug, then fix — see [docs/TESTING.md](docs/TESTING.md) for policy
5. **Creating new skills**: use `superpowers:writing-skills` skill
6. **Issue tracking**: use GitHub issues via `gh` — create with `gh issue create`, view with `gh issue view <n>`, list ready work with `gh issue list`; when a superpowers skill is invoked for an issue, immediately comment `/claim` or assign yourself and edit the issue to set in-progress; if execution doesn't complete before agent stops, unassign and remove the in-progress label to reset
7. **When the user says to remember something**: document it in the appropriate `docs/` file (or CLAUDE.md for agent rules); for actionable follow-ups, create a GitHub issue

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
- Custom AI skills (Claude Code + opencode) → `skills/` (see docs/DEVELOPMENT.md for authoring conventions)


## Issue Tracking

This project uses **GitHub issues** for issue tracking.

### Quick Reference

```bash
gh issue list                  # List open issues
gh issue view <n>             # View issue details
gh issue create               # Create a new issue
gh issue close <n>            # Close an issue
```

### Rules

- Use `gh` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- When a superpowers skill is invoked for an issue, assign yourself and mark it in-progress
- For persistent knowledge, document it in the appropriate `docs/` file — do NOT use MEMORY.md files

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
