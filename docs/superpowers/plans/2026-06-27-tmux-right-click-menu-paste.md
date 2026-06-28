# tmux Right-Click Menu with Custom Paste — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the direct right-click-to-paste binding with tmux's `display-menu` (stock items + custom "Paste" row), gated to non-SSH sessions.

**Architecture:** Move the `MouseDown3Pane` binding from `tmux/tmux-conf` into a new `tmux/tmux-right-click-menu.conf`, sourced conditionally via `if-shell`. This avoids embedding the 200+ character `display-menu` string (with nested `#{}` and double quotes) inside a double-quoted `if-shell` argument — the quoting risk the spec flagged. The `if-shell` SSH gate stays in `tmux/tmux-conf`; only the binding moves.

**Spec refinement note:** The spec (section "Binding") says to edit `tmux/tmux-conf:143-147` inline. The plan refines this to a sourced file because the real stock menu (captured from `tmux list-keys -T root MouseDown3Pane` on tmux 3.6b) is far larger than the spec anticipated — 15+ context-sensitive items with `#{}` conditionals and double-quoted format strings. Inlining inside `if-shell "..."` would require escaping every `"` as `\"`, producing an unreadable, fragile single line. The sourced-file approach follows the existing `source-file` pattern already at `tmux/tmux-conf:343-344`.

**Tech Stack:** tmux 3.6b, bats-core (integration tests), Docker (full test suite)

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `tmux/tmux-right-click-menu.conf` | **Create** | Full `MouseDown3Pane` binding: `if-shell` conditional (pass mouse to app vs show menu) + `display-menu` with stock items from 3.6b defaults + custom Paste row at top. Also the `copy-mode-vi` direct-paste binding. |
| `tmux/tmux-conf:139-147` | **Modify** | Replace the inline `unbind`/`bind` block with a single `if-shell` SSH gate that `source-file`s the new conf. |
| `tests/integration/tmux_environment.bats:69-77` | **Modify** | Update existing `tmux-paste.sh` test to `grep -r` on `$DOTFILES/tmux/` (reference moves to sourced file). Add new test asserting `display-menu` is used for `MouseDown3Pane`. |
| `docs/ARCHITECTURE.md` (Tmux Configuration section) | **Modify** | Add note that the right-click menu is a hand-maintained override; after tmux upgrades, re-run `tmux list-keys -T root MouseDown3Pane` to reconcile. |

---

## Task 1: Write the failing test for display-menu

**Files:**
- Modify: `tests/integration/tmux_environment.bats` (add new test after line 77)

- [ ] **Step 1: Add the failing test**

Add this test at the end of `tests/integration/tmux_environment.bats` (after line 77):

```bash
@test "right-click uses display-menu (not direct paste)" {
  run grep -rE "MouseDown3Pane.*display-menu" "$DOTFILES/tmux/"
  assert_success
}
```

Uses `grep -r` on the whole `tmux/` directory because the binding will live in the sourced file, not the main config. Follows the pattern already used by tests at lines 42 and 47 (`grep -r ... "$DOTFILES/tmux/"`).

- [ ] **Step 2: Run the test to verify it fails**

Run: `just test-unit tests/integration/tmux_environment.bats`
Expected: FAIL — no file in `tmux/` contains `MouseDown3Pane.*display-menu` yet.

- [ ] **Step 3: Commit the failing test**

```bash
git add tests/integration/tmux_environment.bats
git commit -m "test(tmux): add failing test for right-click display-menu"
```

---

## Task 2: Create the menu binding file

**Files:**
- Create: `tmux/tmux-right-click-menu.conf`

- [ ] **Step 1: Create the binding file**

Create `tmux/tmux-right-click-menu.conf` with this exact content:

```tmux
# tmux/tmux-right-click-menu.conf
#
# Right-click pane menu with custom Paste item at the top.
# Sourced conditionally by tmux/tmux-conf only on non-SSH sessions.
#
# Stock menu items captured from tmux 3.6b defaults via:
#   tmux list-keys -T root MouseDown3Pane
# After a tmux upgrade, re-run that command and reconcile any new/changed
# items — tmux has no "extend the default menu" hook, so we hardcode the
# stock entries and they don't auto-inherit upstream changes.

bind-key -n MouseDown3Pane if-shell -F -t = "#{||:#{mouse_any_flag},#{&&:#{pane_in_mode},#{?#{m/r:(copy|view)-mode,#{pane_mode}},0,1}}}" { select-pane -t = ; send-keys -M } { display-menu -T "#[align=centre]#{pane_index} (#{pane_id})" -t = -x M -y M 'Paste' 'p' { run-shell '#{DOTFILES}/scripts/tmux-paste.sh' } '' "#{?#{m/r:(copy|view)-mode,#{pane_mode}},Go To Top,}" < { send-keys -X history-top } "#{?#{m/r:(copy|view)-mode,#{pane_mode}},Go To Bottom,}" > { send-keys -X history-bottom } '' "#{?mouse_word,Search For #[underscore]#{=/9/...:mouse_word},}" C-r { if-shell -F "#{?#{m/r:(copy|view)-mode,#{pane_mode}},0,1}" "copy-mode -t=" ; send-keys -X -t = search-backward -- "#{q:mouse_word}" } "#{?mouse_word,Type #[underscore]#{=/9/...:mouse_word},}" C-y { copy-mode -q ; send-keys -l "#{q:mouse_word}" } "#{?mouse_word,Copy #[underscore]#{=/9/...:mouse_word},}" c { copy-mode -q ; set-buffer "#{q:mouse_word}" } "#{?mouse_line,Copy Line,}" l { copy-mode -q ; set-buffer "#{q:mouse_line}" } '' "#{?mouse_hyperlink,Type #[underscore]#{=/9/...:mouse_hyperlink},}" C-h { copy-mode -q ; send-keys -l "#{q:mouse_hyperlink}" } "#{?mouse_hyperlink,Copy #[underscore]#{=/9/...:mouse_hyperlink},}" h { copy-mode -q ; set-buffer "#{q:mouse_hyperlink}" } '' "Horizontal Split" h { split-window -h } "Vertical Split" v { split-window -v } '' "#{?#{>:#{window_panes},1},,-}Swap Up" u { swap-pane -U } "#{?#{>:#{window_panes},1},,-}Swap Down" d { swap-pane -D } "#{?pane_marked_set,,-}Swap Marked" s { swap-pane } '' Kill X { kill-pane } Respawn R { respawn-pane -k } "#{?pane_marked,Unmark,Mark}" m { select-pane -m } "#{?#{>:#{window_panes},1},,-}#{?window_zoomed_flag,Unzoom,Zoom}" z { resize-pane -Z } }

bind-key -T copy-mode-vi MouseDown3Pane run '#{DOTFILES}/scripts/tmux-paste.sh --copy-mode'
```

Structure of the root binding:
1. `if-shell -F` conditional: if the pane has `mouse_any_flag` set (e.g. vim with mouse enabled) OR is in a non-copy/view mode, pass the mouse event through with `send-keys -M`. Otherwise show the menu.
2. `display-menu` with: **Paste** (our custom item, key `p`) → separator → copy-mode navigation (Go To Top/Bottom) → mouse_word actions (Search/Type/Copy) → mouse_line (Copy Line) → mouse_hyperlink actions (Type/Copy) → separator → pane management (Split/Swap/Kill/Respawn/Mark/Zoom).
3. Copy-mode-vi binding: unchanged from current config — direct paste, no menu.

- [ ] **Step 2: Verify the file exists and has the binding**

Run: `grep -c "display-menu" tmux/tmux-right-click-menu.conf`
Expected: `1`

- [ ] **Step 3: Commit**

```bash
git add tmux/tmux-right-click-menu.conf
git commit -m "feat(tmux): add right-click menu conf with custom Paste item"
```

---

## Task 3: Update tmux-conf to source the binding file

**Files:**
- Modify: `tmux/tmux-conf:139-147`

- [ ] **Step 1: Read the current block to confirm exact text**

Run: `sed -n '139,147p' tmux/tmux-conf`
Expected output:
```
# Paste with right click
# Skip the custom binding over SSH: the terminal/SSH client's native right-click
# paste already sends the local clipboard, and remote hosts usually lack
# pbpaste/xclip, so our binding would paste nothing even if it fired.
if-shell '[ -z "$SSH_TTY" ] && [ -z "$SSH_CLIENT" ] && [ -z "$SSH_CONNECTION" ]' " \
    unbind-key -n MouseDown3Pane; \
    bind-key -T copy-mode-vi MouseDown3Pane run '#{DOTFILES}/scripts/tmux-paste.sh --copy-mode'; \
    bind-key -n MouseDown3Pane run '#{DOTFILES}/scripts/tmux-paste.sh' \
"
```

- [ ] **Step 2: Replace the block**

Replace lines 139–147 (the comment + `if-shell` block) with:

```tmux
# Right-click pane menu with custom Paste item
# Skip the custom binding over SSH: the terminal/SSH client's native right-click
# paste already sends the local clipboard, and remote hosts usually lack
# pbpaste/xclip, so our binding would paste nothing even if it fired.
# Stock menu items are maintained in tmux/tmux-right-click-menu.conf; after a
# tmux upgrade, re-run: tmux list-keys -T root MouseDown3Pane
if-shell '[ -z "$SSH_TTY" ] && [ -z "$SSH_CLIENT" ] && [ -z "$SSH_CONNECTION" ]' "source-file '#{DOTFILES}/tmux/tmux-right-click-menu.conf'"
```

The `if-shell` SSH gate is preserved exactly (same `$SSH_TTY` / `$SSH_CLIENT` / `$SSH_CONNECTION` condition). The body changes from inline `unbind`/`bind` commands to a single `source-file` call. `#{DOTFILES}` is expanded by tmux's format string parser — the same mechanism the existing `run '#{DOTFILES}/scripts/tmux-paste.sh'` binding uses.

- [ ] **Step 3: Verify the old binding is gone and the new one is in place**

Run: `grep -n "MouseDown3Pane" tmux/tmux-conf`
Expected: no output (the binding is no longer in this file).

Run: `grep -n "source-file.*tmux-right-click-menu" tmux/tmux-conf`
Expected: one match on the `if-shell` line.

- [ ] **Step 4: Commit**

```bash
git add tmux/tmux-conf
git commit -m "feat(tmux): source right-click menu conf conditionally on non-SSH"
```

---

## Task 4: Update existing tmux-paste.sh test to grep recursively

**Files:**
- Modify: `tests/integration/tmux_environment.bats:74-77`

The existing test greps `$TMUX_CONF` (the main config file) for `scripts/tmux-paste.sh`. After Task 3, that reference moved to `tmux/tmux-right-click-menu.conf`. The test must grep the whole `tmux/` directory instead.

- [ ] **Step 1: Update the test**

Change this test (lines 74–77):

```bash
@test "right-click paste uses tmux-paste helper script" {
  run grep -E "scripts/tmux-paste.sh" "$TMUX_CONF"
  assert_success
}
```

to:

```bash
@test "right-click paste uses tmux-paste helper script" {
  run grep -rE "scripts/tmux-paste.sh" "$DOTFILES/tmux/"
  assert_success
}
```

`grep -r` on `$DOTFILES/tmux/` finds the reference in the sourced file. Same pattern as tests at lines 42 and 47.

- [ ] **Step 2: Run all tmux tests to verify both pass**

Run: `just test-unit tests/integration/tmux_environment.bats`
Expected: all tests PASS, including:
- `right-click paste binding is gated to non-SSH sessions` (still greps `$TMUX_CONF` for `if-shell.*SSH_TTY` — still present in `tmux-conf`)
- `right-click paste uses tmux-paste helper script` (now greps `$DOTFILES/tmux/` recursively — finds it in `tmux-right-click-menu.conf`)
- `right-click uses display-menu (not direct paste)` (greps `$DOTFILES/tmux/` recursively — finds it in `tmux-right-click-menu.conf`)

- [ ] **Step 3: Commit**

```bash
git add tests/integration/tmux_environment.bats
git commit -m "test(tmux): update paste test for sourced menu conf"
```

---

## Task 5: Run full unit test suite

- [ ] **Step 1: Run all unit tests**

Run: `just test-unit`
Expected: all tests PASS (no regressions in other test files).

- [ ] **Step 2: If any test fails, debug and fix before proceeding**

Common failure: the `right-click paste binding is gated to non-SSH sessions` test (line 69–72) greps `$TMUX_CONF` for `if-shell.*SSH_TTY.*SSH_CLIENT.*SSH_CONNECTION`. This still passes because the `if-shell` with the SSH condition is still in `tmux-conf` — only its body changed from inline binds to `source-file`. If it fails, check that the `if-shell` line in `tmux-conf` still contains all three SSH variables.

---

## Task 6: Document the drift trade-off in ARCHITECTURE.md

**Files:**
- Modify: `docs/ARCHITECTURE.md` (Tmux Configuration section, around line 104–109)

- [ ] **Step 1: Read the current Tmux Configuration section**

Run: `sed -n '104,110p' docs/ARCHITECTURE.md`
Expected:
```
## Tmux Configuration

- **`tmux/tmux-conf`**: Main tmux configuration
- Prefix key: `Ctrl-f`
- Integration with system clipboard via reattach-to-user-namespace
- Predefined layouts via shell functions: `tmux-large`, `tmux-small`, `tmux-xl`
```

- [ ] **Step 2: Add the drift note**

After the predefined layouts bullet, add:

```markdown
- **`tmux/tmux-right-click-menu.conf`**: Right-click pane menu with custom Paste item
  - Sourced conditionally by `tmux-conf` on non-SSH sessions only
  - Stock menu items are hand-maintained (tmux has no "extend the default menu" hook)
  - After a tmux upgrade, re-run `tmux list-keys -T root MouseDown3Pane` and reconcile any new/changed entries
```

- [ ] **Step 3: Commit**

```bash
git add docs/ARCHITECTURE.md
git commit -m "docs: document tmux right-click menu override in ARCHITECTURE.md"
```

---

## Task 7: Run full test suite in Docker

- [ ] **Step 1: Run the Docker test suite**

Run: `just test`
Expected: all tests PASS (goss infrastructure assertions + bats integration tests).

This validates that the Docker container (where `DOTFILES=/dotfiles`) can resolve `#{DOTFILES}/tmux/tmux-right-click-menu.conf` — the repo is copied to `/dotfiles` in the Dockerfile, so the path resolves correctly.

- [ ] **Step 2: If any test fails, debug and fix**

If the `source-file` path resolution fails in Docker, verify that `DOTFILES` is set in the tmux environment. The Dockerfile sets `ENV DOTFILES=/dotfiles` (line 4), and the repo is copied to `/dotfiles` (line 43), so `#{DOTFILES}/tmux/tmux-right-click-menu.conf` resolves to `/dotfiles/tmux/tmux-right-click-menu.conf`.

---

## Task 8: Manual verification (if a live tmux session is available)

This task is optional — it can't run in CI or Docker. Skip if no TTY is available.

- [ ] **Step 1: Source the updated config in a live tmux session**

Inside tmux, press `prefix r` (Ctrl-f r) to reload the config. Or run:
```
tmux source-file ~/.tmux.conf
```

- [ ] **Step 2: Right-click a pane and verify the menu appears**

Expected: a menu pops up at the cursor with "Paste" at the top, followed by the stock items (Go To Top, Go To Bottom, Search For..., Horizontal Split, Vertical Split, Swap Up/Down, Kill, Respawn, Mark, Zoom).

- [ ] **Step 3: Click "Paste" and verify system clipboard is pasted**

Copy something to the system clipboard (e.g. select text in another app, Cmd-C). Right-click the tmux pane, click "Paste". Expected: the clipboard content is pasted into the pane and "pasted!" appears briefly.

- [ ] **Step 4: Right-click inside a pane running vim (or any app with mouse support)**

Expected: the mouse event is passed through to the application (no menu appears). This is the `if-shell -F` conditional in the binding — `mouse_any_flag` is set when the app has enabled mouse support.

- [ ] **Step 5: Verify SSH gating (if possible)**

SSH into the machine running this config. Right-click a pane. Expected: tmux's stock menu appears (no "Paste" item) — the custom binding was not installed because `$SSH_TTY` is set.
