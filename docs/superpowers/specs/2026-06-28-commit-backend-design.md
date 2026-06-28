# `commit` — configurable AI backend (claude ↔ opencode)

**Date:** 2026-06-28
**Status:** Approved design

## Summary

Make the `commit` command's AI message generation backend configurable between
Claude (`claude -p --model haiku`, today's behavior) and opencode
(`opencode run`, defaulting to Kimi 2.7). Selection is driven by a single
environment variable whose default is stored — and switched — in this dotfiles
repo's tracked shell config, so the choice syncs across machines via git. No
local state file.

## Motivation

The backend is currently hard-coded to `claude --model haiku`
(`lib/commands.sh:146`). Switching to opencode/Kimi for a machine or a session
requires editing the function. A small config surface lets the user pick the
backend (and override the model) without touching the implementation, and —
because the default lives in the committed `bash_profile` — the choice
propagates to every machine the dotfiles are deployed on. A local state file
was considered and rejected: it would not sync, which is the opposite of what a
dotfiles repo wants.

## Configuration surface

Two environment variables, read at runtime with `${VAR:-default}` fallbacks
(consistent with `DOTFILES_COMMIT_SEPARATOR` in `lib/_shared.sh:56`):

| Variable | Purpose | Default |
|----------|---------|---------|
| `DOTFILES_COMMIT_BACKEND` | Which backend: `claude` or `opencode` | `claude` |
| `DOTFILES_COMMIT_MODEL` | Optional model override, applied to the active backend | unset → per-backend default |

**Per-backend default model:**

- `claude` → `haiku`
- `opencode` → `opencode-go/kimi-k2.7-code` (the only Kimi 2.7 id opencode
  exposes; verified via `opencode models`)

**Precedence (effective backend):** `DOTFILES_COMMIT_BACKEND` → built-in
`claude`. A value other than `claude`/`opencode` prints a warning to stderr and
falls back to `claude`.

**Persistence = the repo.** The editable default lives in tracked
`bash_profile`, near the other exports:

```bash
export DOTFILES_COMMIT_BACKEND=claude   # or: opencode (uses Kimi 2.7)
```

- Switch backend: edit that line, commit, open a new shell — syncs everywhere.
- Switch back: flip it to `claude`.
- One-off without editing: `DOTFILES_COMMIT_BACKEND=opencode commit` (env prefix).

## Components

All changes are in `lib/commands.sh` unless noted.

### 1. `_dotfiles_commit_backend` (new helper)

Resolves and validates the effective backend name. Echoes `claude` or
`opencode`.

```bash
function _dotfiles_commit_backend ()
{
  local backend="${DOTFILES_COMMIT_BACKEND:-claude}"
  case "$backend" in
    claude|opencode) printf '%s' "$backend" ;;
    *)
      printf 'unknown DOTFILES_COMMIT_BACKEND=%s, using claude\n' "$backend" >&2
      printf '%s' 'claude'
      ;;
  esac
}
```

### 2. `_dotfiles_commit_model` (new helper)

Resolves the model: explicit override wins, else the per-backend default.

```bash
function _dotfiles_commit_model ()
{
  local backend="$1"
  if [ -n "$DOTFILES_COMMIT_MODEL" ]
  then
    printf '%s' "$DOTFILES_COMMIT_MODEL"
    return
  fi
  case "$backend" in
    opencode) printf '%s' 'opencode-go/kimi-k2.7-code' ;;
    *)        printf '%s' 'haiku' ;;
  esac
}
```

### 3. `_dotfiles_commit_generate_message` (refactor)

Resolve backend + model, check the backend's binary is available (the backend
name doubles as the binary name — `claude`/`opencode`), then dispatch. The diff
is piped on stdin for both backends (verified: `opencode run` reads stdin and
merges it into the prompt). opencode's banner goes to stderr, so suppress it to
keep the spinner clean; opencode writes the message cleanly to stdout.

```bash
local backend model
backend=$(_dotfiles_commit_backend)
model=$(_dotfiles_commit_model "$backend")

if ! command -v "$backend" > /dev/null 2>&1
then
  return 1
fi

# ... mktemp outfile ...

case "$backend" in
  opencode)
    git diff --cached | head -c 100000 \
      | opencode run --model "$model" "$(_dotfiles_commit_prompt "$ticket")" \
        > "$outfile" 2> /dev/null &
    ;;
  *)
    git diff --cached | head -c 100000 \
      | claude -p --model "$model" "$(_dotfiles_commit_prompt "$ticket")" \
        > "$outfile" &
    ;;
esac
local pid=$!
```

Everything downstream — spinner wait, 130/interrupt handling, sanitizing, empty
→ failure — stays as-is.

### 4. `commit` fallback message (minor)

The "claude unavailable" message becomes backend-aware so the fallback note is
accurate:

```bash
echo "$(_dotfiles_commit_backend) unavailable, falling back to manual commit" >&2
```

### 5. `commit-backend` (new, read-only status command)

Prints the effective backend and model — no side effects, no persistence.

```bash
function commit-backend ()
{
  local backend model
  backend=$(_dotfiles_commit_backend)
  model=$(_dotfiles_commit_model "$backend")
  printf 'backend: %s\nmodel:   %s\n' "$backend" "$model"
}
```

### 6. `bash_profile` (tracked default)

Add the editable default export alongside the other `export` lines:

```bash
export DOTFILES_COMMIT_BACKEND=claude   # or: opencode (uses Kimi 2.7)
```

## Testing

Per the repo TDD rule, add bats unit tests under `tests/` (extending the
existing `tests/commit_*.bats` suites). Stub `claude` and `opencode`; set the
env vars directly (no state file to manage). Cases:

1. Default (no env) → backend `claude`, model `haiku`; claude invoked with
   `--model haiku`.
2. `DOTFILES_COMMIT_BACKEND=opencode` → `opencode run --model
   opencode-go/kimi-k2.7-code` invoked; message captured from stdout.
3. `DOTFILES_COMMIT_MODEL=foo` with claude backend → claude invoked with
   `--model foo`.
4. `DOTFILES_COMMIT_MODEL=bar` with opencode backend → opencode invoked with
   `--model bar`.
5. Unknown `DOTFILES_COMMIT_BACKEND=bogus` → warns to stderr, behaves as
   `claude`.
6. Active backend binary missing on PATH → falls back to manual `c` (existing
   behavior, now keyed off the active backend).
7. `commit-backend` prints the effective backend and model for both backends.
8. Existing claude-path tests (ticket prefix, sanitizing, empty → fallback)
   continue to pass unchanged.

Run `just test-unit` then `just test` after implementation.

## Out of scope

- Persisting the model choice via a command (env-var override only).
- Backends beyond `claude` and `opencode`.
- Changing the prompt text or the ticket-prefix behavior.
- A `commit-backend <name>` *setter* (switching is editing the committed export).
