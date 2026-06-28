# tmux right-click menu with custom Paste

## Problem

The current tmux config binds `MouseDown3Pane` (right-click) to a direct
`run tmux-paste.sh`, which suppresses tmux's built-in right-click context
menu entirely. There is no menu, so paste works but no other pane operations
(Split, Kill, Swap, etc.) are reachable from the mouse.

## Goal

Restore tmux's built-in right-click `display-menu` (Option B) and add a
custom "Paste" row to it that pulls from the system clipboard via the
existing `scripts/tmux-paste.sh`. Right-click keeps paste as a one-click
action *and* gains the rest of the stock pane menu.

## Non-goals

- Middle-click paste (`MouseDown2Pane`).
- Paste via prefix (`prefix ]`).
- Any change to `tmux-paste.sh` itself — its `set-buffer` / `paste-buffer -p`
  / `display-message 'pasted!'` behavior is reused as-is.
- Conditionally hiding the Paste row inside the menu when no clipboard tool
  is present. The SSH gate (below) is the only guard. On a local Linux box
  without xclip the row pastes empty, which matches today's behavior.

## Design

### Binding (local, non-SSH only)

`tmux/tmux-conf:143-147` currently does:

```tmux
if-shell '[ -z "$SSH_TTY" ] && [ -z "$SSH_CLIENT" ] && [ -z "$SSH_CONNECTION" ]' " \
    unbind-key -n MouseDown3Pane; \
    bind-key -T copy-mode-vi MouseDown3Pane run '#{DOTFILES}/scripts/tmux-paste.sh --copy-mode'; \
    bind-key -n MouseDown3Pane run '#{DOTFILES}/scripts/tmux-paste.sh' \
"
```

Replace it with a single root-table binding to a `display-menu` whose items
are the stock pane-menu entries plus a "Paste" row, and a matching
copy-mode-vi variant that passes `--copy-mode`:

```tmux
if-shell '[ -z "$SSH_TTY" ] && [ -z "$SSH_CLIENT" ] && [ -z "$SSH_CONNECTION" ]' " \
    bind-key -n MouseDown3Pane display-menu -t= -xM -yM -O \
        'Paste' 'p' { run-shell '#{DOTFILES}/scripts/tmux-paste.sh' } \
        '' \
        '<stock item 1>' '<key>' { <cmd> } \
        ... \
        '<stock item N>' '<key>' { <cmd> }; \
    bind-key -T copy-mode-vi MouseDown3Pane run-shell '#{DOTFILES}/scripts/tmux-paste.sh --copy-mode' \
"
```

tmux `if-shell` takes a shell-quoted string, so nested single quotes around
`#{DOTFILES}` must be escaped (`\'`) or replaced with the literal path. The
block stays inside one `if-shell` so the SSH gate still trivially suppresses
everything.

### Stock menu items

tmux has no "extend the default menu" hook — we must list entries ourselves.
Implementation step 1 is to capture the **real** default for 3.6b by running,
inside a tmux session with the custom binding removed:

```bash
tmux list-keys -T root MouseDown3Pane
```

and transcribe its `display-menu` items into our binding. Expected entries
(tmux 3.x defaults, to be verified live): Split Horizontal, Split Vertical,
Swap With Previous, Swap With Next, Break Pane, Kill Pane, Respawn Pane,
Mark/Unmark, Zoom/Unzoom, New Window.

The "Paste" row goes at the **top** of the menu so paste stays one click and
matches current right-click-to-paste muscle memory.

### Paste row mechanics

- Root table: `'Paste' 'p' { run-shell '#{DOTFILES}/scripts/tmux-paste.sh' }`.
  `run-shell` (not `run`) is the correct command inside a menu command block.
  No `--copy-mode` arg — we are not in copy mode at the root binding.
- Copy-mode-vi table: a separate `bind-key -T copy-mode-vi MouseDown3Pane`
  that calls `tmux-paste.sh --copy-mode` directly (no menu in copy mode —
  matches today's behavior, where copy-mode right-click just pastes).

Question to resolve during implementation: does the menu need a `cancel` on
copy-mode-vi, or should copy-mode right-click keep the direct-paste path?
Default in the spec: keep direct-paste in copy mode (no menu there), since
that's the existing UX and copy mode has its own key table semantics.

### SSH gating (unchanged)

`if-shell '[ -z "$SSH_TTY" ] && [ -z "$SSH_CLIENT" ] && [ -z "$SSH_CONNECTION" ]'`
gates the entire binding block. Over SSH:

- No custom `MouseDown3Pane` binding is installed.
- tmux's stock menu shows on right-click (no Paste row).
- `pbpaste` / `xclip` are assumed absent; terminal-native right-click paste
  is left to the SSH client.

Identical to today.

### Tests

`tests/integration/tmux_environment.bats:69-77` currently asserts:

1. The SSH `if-shell` gate (`SSH_TTY` / `SSH_CLIENT` / `SSH_CONNECTION`).
2. The reference to `scripts/tmux-paste.sh`.

Both still hold. Add one assertion that the root binding uses `display-menu`:

```bash
@test "right-click uses display-menu (not direct paste)" {
  run grep -E "MouseDown3Pane.*display-menu" "$TMUX_CONF"
  assert_success
}
```

so a regression to direct-paste fails. No new script logic, so `just
test-unit` is sufficient; `just test` is the Docker gate.

## Implementation plan (sketch)

1. On a machine running tmux 3.6b with the custom binding disabled, run
   `tmux list-keys -T root MouseDown3Pane` and transcribe the stock items.
2. Edit `tmux/tmux-conf:143-147` per the Design section. Pay attention to
   `if-shell` quoting: the inner binding is one shell-quoted string; any
   nested single quotes around `#{DOTFILES}` must be escaped (`\'` inside the
   double-quoted string) or replaced with the literal path.
3. Add the `display-menu` assertion to `tests/integration/tmux_environment.bats`.
4. Run `just test-unit`, then `just test` in Docker.
5. **Document the drift trade-off in `docs/ARCHITECTURE.md`** — add a note
   under the "Tmux Configuration" section that the right-click menu is a
   hand-maintained override of tmux's default `display-menu` items (tmux has
   no "extend the default menu" hook; re-listing items is the only supported
   way to customize). After a tmux upgrade, re-run
   `tmux list-keys -T root MouseDown3Pane` and reconcile the stock entries.

## Risks

- **`if-shell` escaping.** The current block works; the new one adds nested
  menu-item strings. Validate by sourcing the new `tmux-conf` in a live tmux
  session and right-clicking a pane.
- **Menu item drift.** Stock items captured from 3.6b may differ from what
  the user sees on another machine or after a tmux upgrade. This is the one
  real trade-off of overriding the default menu: because tmux has no "extend
  the default menu" hook, we hardcode the stock items, so new/renamed
  defaults in future tmux versions won't be inherited until we re-capture
  them. Acceptable: the dotfiles target this user's machines on 3.6b, the
  entries are easy to edit, and step 5 of the implementation plan documents
  the resync procedure in `docs/ARCHITECTURE.md`.
- **Copy-mode-vi binding regression.** Today it's `run ... --copy-mode`. If
  the new design switches it to `run-shell`, verify the script still exits
  copy mode (it already does via `send -X cancel`).