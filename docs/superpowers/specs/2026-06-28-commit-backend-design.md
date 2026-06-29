# `commit` — configurable AI backend (claude ↔ opencode)

**Date:** 2026-06-28
**Status:** Approved design

## Summary

Make the `commit` command's AI message generation backend configurable between
Claude (`claude -p --model haiku`, today's behavior) and opencode
(`opencode run`, defaulting to Kimi 2.7). The backend is driven by a single
environment variable, surfaced through `commit`'s own subcommands rather than a
separate command. Each backend's model is a fixed default defined in this repo
(`lib/commands.sh`) — not a runtime knob:

- `commit` — stage and AI-commit (unchanged default behavior).
- `commit status` — show the active backend, model, and availability.
- `commit backend <claude|opencode>` — switch the backend for the current shell.

The durable, cross-machine default lives in this dotfiles repo's tracked
`bash_profile` export, so it syncs via git. No local state file.

## Motivation

The backend is currently hard-coded to `claude --model haiku`
(`lib/commands.sh:146`). A small config surface lets the user pick the backend
without editing the function; each backend's model stays a fixed default in the
repo (changing a model is a one-line edit in `lib/commands.sh`, kept in version
control like the rest of the dotfiles). Centralizing it under
`commit`'s own args — instead of a second top-level command — keeps one
discoverable CLI. The persistent default lives in the committed `bash_profile`
so it propagates to every machine; `commit backend <name>` is an ad-hoc switch
layered on top for the current shell. A local state file was considered and
rejected: it would not sync, the opposite of what a dotfiles repo wants.

## Configuration surface

One environment variable, read at runtime with a `${VAR:-default}` fallback
(consistent with `DOTFILES_COMMIT_SEPARATOR` in `lib/_shared.sh:56`):

| Variable | Purpose | Default |
|----------|---------|---------|
| `DOTFILES_COMMIT_BACKEND` | Which backend: `claude` or `opencode` | `claude` |

**Per-backend default model** — fixed in `_dotfiles_commit_model`
(`lib/commands.sh`); the single place to change a backend's model:

- `claude` → `haiku`
- `opencode` → `opencode-go/kimi-k2.7-code` (the only Kimi 2.7 id opencode
  exposes; verified via `opencode models`)

**Precedence (effective backend):** `DOTFILES_COMMIT_BACKEND` → built-in
`claude`. A value other than `claude`/`opencode` prints a warning to stderr and
falls back to `claude`.

**How the value gets set:**

- **Durable / cross-machine default** — the committed export in `bash_profile`
  (see component 6). Edit it, commit, open a new shell; syncs everywhere.
- **Current shell** — `commit backend opencode` runs `export
  DOTFILES_COMMIT_BACKEND=opencode`. Because `commit` is a shell function (not a
  subshell), the export persists for the rest of the session. Reverting:
  `commit backend claude`.
- **Single invocation** — `DOTFILES_COMMIT_BACKEND=opencode commit` (env prefix).

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

Returns the fixed default model for a backend. This `case` is the single place
to change a backend's model.

```bash
function _dotfiles_commit_model ()
{
  local backend="$1"
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

### 4. `commit` dispatcher (subcommands)

`commit` gains a `case` on its first argument, run **before** the existing
merge/stage/commit logic. `status` and `backend` are reserved subcommands;
anything else (including no args) falls through to today's commit behavior —
safe because `commit` currently ignores its arguments entirely.

```bash
function commit ()
{
  case "$1" in
    status)
      local b m avail=no
      b=$(_dotfiles_commit_backend)
      m=$(_dotfiles_commit_model "$b")
      command -v "$b" > /dev/null 2>&1 && avail=yes
      printf 'backend:   %s\nmodel:     %s\navailable: %s\n' "$b" "$m" "$avail"
      return 0
      ;;
    backend)
      shift
      if [ -z "$1" ]
      then
        # getter: print current effective backend
        printf '%s\n' "$(_dotfiles_commit_backend)"
        return 0
      fi
      case "$1" in
        claude|opencode)
          export DOTFILES_COMMIT_BACKEND="$1"
          printf 'commit backend set to %s (model: %s) for this shell\n' \
            "$1" "$(_dotfiles_commit_model "$1")"
          return 0
          ;;
        *)
          printf 'unknown backend: %s (expected claude or opencode)\n' "$1" >&2
          return 1
          ;;
      esac
      ;;
  esac

  # ... existing commit body (MERGE_HEAD check, git add -A, generate, commit) ...
}
```

The `export` must land in the interactive shell, so the `backend` setter is
handled inline in `commit` (not via command substitution, which would run in a
subshell and discard the export).

### 5. `commit` fallback message (minor)

The "claude unavailable" message in the existing commit body becomes
backend-aware so the fallback note is accurate:

```bash
echo "$(_dotfiles_commit_backend) unavailable, falling back to manual commit" >&2
```

### 6. `bash_profile` (tracked durable default)

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
3. Unknown `DOTFILES_COMMIT_BACKEND=bogus` → warns to stderr, behaves as
   `claude`.
4. Active backend binary missing on PATH → falls back to manual `c` (existing
   behavior, now keyed off the active backend).
5. `commit status` → prints backend, model, and availability for both backends.
6. `commit backend opencode` → exports `DOTFILES_COMMIT_BACKEND=opencode`
   (assert by calling the function directly — **not** via bats `run`, which
   subshells and discards the export — then checking the variable / `commit
   status`). `commit backend claude` reverts.
7. `commit backend` (no value) → prints the current effective backend.
8. `commit backend bogus` → error to stderr, returns 1, leaves the variable
   unchanged.
9. A non-subcommand arg (e.g. `commit wip`) still runs the normal commit path.
10. Existing claude-path tests (ticket prefix, sanitizing, empty → fallback)
    continue to pass unchanged.

Run `just test-unit` then `just test` after implementation.

## Out of scope

- Runtime model overrides (no `DOTFILES_COMMIT_MODEL`, no `commit model`
  setter). Each backend's model is a fixed default in `_dotfiles_commit_model`;
  `commit status` displays it. Changing a model is a code edit.
- Writing the durable default automatically (switching the committed default is
  a manual `bash_profile` edit; `commit backend` only affects the live shell).
- Backends beyond `claude` and `opencode`.
- Changing the prompt text or the ticket-prefix behavior.
