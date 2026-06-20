# `commit` — AI-generated commit via Claude Haiku

**Date:** 2026-06-20
**Status:** Approved design

## Summary

Replace the existing `alias commit='git commit -ev'` with a shell function that
stages all changes, asks a Claude Haiku model to write a commit message from the
staged diff, and commits — falling back to the existing `c` function (manual
commit editor) whenever Haiku is unavailable or errors.

## Motivation

A single `commit` command that stages everything and writes a sensible message
removes the friction of hand-writing routine commit messages, while staying
consistent with the repo's existing ticket-prefix convention and commit rules
(single-line, no `Co-Authored-By`).

## Location

`lib/commands.sh` — remove the `alias commit='git commit -ev' # non-signed commit`
line (currently line 898) and add a `commit` function near the related `c`/`cn`
functions (top of the file). The function reuses existing helpers from
`lib/_shared.sh`:

- `_dotfiles_grep_ticket_number` — parse ticket id from the current branch name
- `_dotfiles_commit_message` — build `TICKET: message` (separator configurable
  via `DOTFILES_COMMIT_SEPARATOR`, default `:`)
- `_dotfiles_git_log_commit` / `_dotfiles_git_status` — post-commit output

## Behavior

In order:

1. `git add -A` — stage all changes (tracked, untracked, deletions).
2. If nothing is staged (`git diff --cached --quiet`), print `nothing to commit`
   and return 0.
3. Parse the branch ticket:
   `ticket=$(git branch --show-current 2>/dev/null | _dotfiles_grep_ticket_number)`
4. Generate the message with Haiku (see "Message generation" below). If
   generation fails for **any** reason, fall back to `c` (see "Fallback").
5. Build the final message: `message=$(_dotfiles_commit_message "$ticket" "$generated")`.
6. Commit and report:
   `git commit -m "$message" && _dotfiles_git_log_commit && _dotfiles_git_status`

## Message generation

Pipe the staged diff to Claude Code in print mode (text only — no tools, no
permission prompts):

```bash
git diff --cached | head -c 100000 | claude -p --model haiku "<prompt>"
```

- The diff is capped (`head -c 100000`, ~100KB) to avoid pathological token
  usage on huge diffs; correctness is unaffected for normal commits.
- Print mode (`-p`) makes Haiku emit only generated text and never run git
  itself.

### Conditional prompt (avoids prefix clash)

Because step 5 prepends the ticket, Haiku must **not** also add a Conventional
Commits prefix when a ticket exists — otherwise the message would read
`AB-123: fix(scope): ...` with two competing prefixes. The function selects the
prompt based on whether `$ticket` is non-empty:

- **Ticket present** — instruct Haiku to write a *plain imperative* one-line
  summary, no Conventional Commits prefix. Result: `AB-123: silence brew prompt`.
- **No ticket** — instruct Haiku to use Conventional Commits style when it fits.
  Result: `fix(bootstrap): silence brew prompt`.

Both prompts additionally require: single line only, imperative mood, no
`Co-Authored-By`, no surrounding quotes/backticks, output the message text and
nothing else.

### Sanitizing model output

- Take the first line only (`head -n1`).
- Strip surrounding quotes/backticks and leading/trailing whitespace.
- If the result is empty, treat as a generation failure (fall back).

## Fallback

Any of the following triggers a graceful fallback to the existing `c` function
(opens the commit editor pre-filled with the ticket prefix; user types the
message manually). Changes are already staged from step 1, so `c` just works:

- `claude` not found on `PATH`
- `claude` exits non-zero (network error, out of usage / rate limited, etc.)
- generated message is empty after sanitizing

When falling back, print a short note to stderr (e.g.
`claude unavailable, falling back to manual commit`) then call `c`.

## Testing

Add bats unit tests under `tests/` (per the repo TDD rule for new behavior),
stubbing `claude` and the relevant git plumbing. Cases:

1. Ticket present → final message is `TICKET: <plain summary>`, no Conventional
   prefix; commit invoked with that message.
2. No ticket → final message is Haiku's output verbatim (Conventional allowed),
   no ticket prefix.
3. Nothing staged → prints `nothing to commit`, returns 0, no commit.
4. `claude` missing on PATH → falls back to `c`.
5. `claude` exits non-zero → falls back to `c`.
6. `claude` returns empty output → falls back to `c`.
7. Output sanitizing → multi-line / quoted model output reduced to a clean
   single line.

Run `just test-unit` then `just test` after implementation.

## Out of scope

- Confirmation prompt before committing (design is fully automatic).
- Pushing after commit.
- Configurable model (hard-coded to `haiku`; can be revisited later).
