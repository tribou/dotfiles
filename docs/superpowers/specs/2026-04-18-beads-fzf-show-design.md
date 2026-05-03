# Design: Beads fzf Show Command (`bdr` / `bds`)

**Date:** 2026-04-18
**Bead:** dotfiles-ynp

## Summary

Add an interactive fzf-based command to browse and search all beads issues, with a live preview pane showing full issue detail, and print the selected issue via `bd show` on exit.

## Implementation Location

`lib/fzf.sh` — alongside existing fzf-based shell functions (`fcoc`, `fshow`, `fo`, `z`, `zz`).

## Function: `_dotfiles_beads_show`

### Behavior

1. Run `bd list --all` and pipe output to fzf.
2. fzf configuration:
   - `--ansi` — preserve color codes from `bd list --all` output
   - `--reverse` — top-to-bottom list order (consistent with `fshow`)
   - `--preview 'bd show $(echo {} | awk '"'"'{print $2}'"'"')'` — live preview pane showing full `bd show` output for the highlighted issue as you browse
   - `--preview-window right:60%` — preview on the right side
3. On selection (Enter): extract the issue ID (second token via `awk '{print $2}'`) and call `bd show <id>`, printing output to the terminal.
4. On cancel (Esc or Ctrl-C): exit silently with no output.

### Aliases

Both `bdr` and `bds` are aliases for `_dotfiles_beads_show`, defined immediately after the function in `lib/fzf.sh`.

- `bdr` — primary interactive command (mnemonic: bead read/review)
- `bds` — secondary alias (mnemonic: bead show)

## Input / Output

- **Input:** no arguments; reads from `bd list --all` at call time
- **Output:** `bd show <id>` printed to stdout on selection; nothing on cancel

## Error Handling

- If `bd` is not installed or `bd list --all` returns no results, fzf will display an empty list and exit cleanly on cancel.
- No explicit error handling required beyond fzf's built-in empty-input behavior.

## Testing

Manual verification:
1. Run `bdr` — confirm fzf list appears with ANSI colors and preview pane.
2. Browse issues — confirm preview pane updates with `bd show` output.
3. Select an issue — confirm `bd show <id>` output is printed.
4. Press Esc — confirm silent exit with no output.
5. Confirm `bds` behaves identically to `bdr`.
