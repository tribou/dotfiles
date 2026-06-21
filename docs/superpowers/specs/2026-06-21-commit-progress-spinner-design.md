# `commit` — animated spinner while Claude generates the message

**Date:** 2026-06-21
**Status:** Approved design

## Summary

Add a spinner to `commit` (see `docs/superpowers/specs/2026-06-20-commit-haiku-design.md`)
so the user gets visual feedback while `_dotfiles_commit_generate_message` waits on the
`claude -p --model haiku` call — currently the only step with no output until it returns.

## Motivation

`commit` can sit silently for several seconds while the diff is sent to Claude and a
message comes back. With no indication anything is happening, it's unclear whether the
command is working, hung, or has crashed.

## Scope

The spinner wraps only the Claude generation call (`_dotfiles_commit_generate_message`).
`git add -A` and `git commit` are local and effectively instant — they get no spinner.

## Components

### `_dotfiles_spinner_wait <pid> <label>` (new, `lib/commands.sh`)

Watches an already-backgrounded process and shows progress while it runs.

- **All output goes to stderr, never stdout.** `_dotfiles_commit_generate_message` is
  captured via `generated=$(...)` in `commit()`; anything the spinner wrote to stdout
  would silently corrupt the generated commit message.
- **Interrupt handling (Ctrl-C) is unconditional**, independent of the tty check below.
  The backgrounded pipeline runs in its own process group, so it does *not* receive the
  terminal's SIGINT — only an explicit trap can stop it, and that has to apply
  regardless of whether output is animated, because the orphaned-background-process risk
  exists either way (e.g. `commit 2>/tmp/log` still runs interactively even though
  stderr isn't a tty).
  - `trap 'interrupted=1' INT` is installed once at the top of the function, before the
    tty check, and explicitly cleared (`trap - INT`) before every return. The trap
    **only sets a flag**; it never calls `return`/`exit` itself, because this function
    runs sourced into the user's live interactive shell, where `exit` inside a trap
    would close their terminal.
  - A single polling loop (`while kill -0 "$pid"; do ...; sleep 0.1; done`) checks the
    flag each cycle; when set, it breaks out, kills the backgrounded pid, and the
    function returns `130`.
  - Normal (non-interrupted) completion: `wait "$pid"` and return its real exit status.
- tty detection checks **stderr**, not stdout: `[ -t 2 ]`. This only decides what gets
  *printed* inside the same loop — it does not affect interrupt handling:
  - **stderr is a tty:** each loop cycle redraws one frame of a 10-frame braille spinner
    (`⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏`) at ~100ms/frame: `printf '\r%s %s' "$frame" "$label" >&2`. On
    completion, clear the line (`printf '\r\033[K' >&2`).
  - **stderr is not a tty** (CI, piped, log redirection): print the label once before
    the loop starts (`printf '%s\n' "$label" >&2`), then loop silently — no escape codes
    in logs.

### `_dotfiles_commit_generate_message` (modified)

Currently runs the pipeline synchronously via command substitution. Changes to:

1. Background the existing pipeline, redirecting only stdout to a temp file (stderr is
   left inherited, same as today, so real `claude` error output still surfaces on the
   terminal unchanged):
   ```bash
   git diff --cached | head -c 100000 | claude -p --model haiku "$prompt" > "$outfile" &
   pid=$!
   ```
2. Call `_dotfiles_spinner_wait "$pid" "Asking Claude for a commit message..."`,
   capture its status.
3. **Status `130`:** clean up the temp file and return `130` (propagate the cancel,
   don't treat it as a generation failure).
4. **Status nonzero (other failure):** clean up and return `1`, as today.
5. **Status `0`:** read the temp file, sanitize as today, return the sanitized message
   on stdout (or `1` if sanitizing produces an empty result, as today).

### `commit` (modified)

Distinguishes "user canceled" from "Claude unavailable/errored":

- If `_dotfiles_commit_generate_message` returns `130`: print `commit canceled` to
  stderr and return `130`. Do **not** fall back to `c` — the user explicitly asked to
  stop, so don't drop them into a manual-commit editor they didn't ask for. Nothing has
  been committed; `git add -A` already ran, so changes are simply left staged.
- Any other empty/failed result: unchanged — print `claude unavailable, falling back to
  manual commit` and call `c`.

## Out of scope

- A timeout for a hung `claude` call (not requested; existing design has none either).
- Spinners around `git add`/`git commit` (instant, no feedback needed).
- Preserving/restoring a pre-existing `INT` trap — interactive shells essentially never
  have one set, and `trap - INT` (reset to default) matches that default anyway.

## Testing

`tests/commit_generate_message.bats` exercises the real
`_dotfiles_commit_generate_message` (mocking `git`/`claude`), so it runs the real
`_dotfiles_spinner_wait` too. Under bats, stderr is not a tty, so these tests exercise
the static-label fallback path, not the animation.

- bats' `run` merges stdout+stderr into `$output` by default. The new stderr label line
  would break the existing **exact-match** assertions (e.g.
  `assert_output "fix(bootstrap): silence brew prompt"`). Switch these tests to
  `run --separate-stderr` so `$output` stays stdout-only (existing assertions need no
  change) and add a `$stderr` assertion confirming the label line appears.
- Add tests for `_dotfiles_spinner_wait` directly:
  1. Process completes successfully → returns its exit status; label appears on stderr
     (non-tty path).
  2. Process exits nonzero → that status is returned.
  3. Simulated interrupt (send the function's own trap a SIGINT, or directly set the
     `interrupted` flag path via a fast-exiting backgrounded process plus a sent signal)
     → returns `130`, kills the pid, no stdout output.
- Add one case to `tests/commit_command.bats`: when
  `_dotfiles_commit_generate_message` returns `130`, `commit` prints `commit canceled`,
  returns `130`, and does **not** call `c` or `git commit`.

Run `just test-unit` then `just test` after implementation.
