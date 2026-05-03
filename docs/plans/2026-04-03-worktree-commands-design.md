# Git Worktree Helper Commands

## Overview

Three shell functions added to `lib/commands.sh` for managing git worktrees. All worktrees live in `.worktrees/` inside the repo root.

## Commands

### `wtc <name>` — Create

Creates a new branch and worktree, then `cd`s into it.

- Branch name and worktree directory name are the same (`<name>`)
- Worktree created at `<repo-root>/.worktrees/<name>`
- Always creates a new branch from current HEAD (errors if branch already exists)
- Adds `.worktrees/` to `.gitignore` if not already present
- Branch names with `/` (e.g. `AB-123/my-feature`) naturally create subdirectories

```bash
# in ~/dev/myapp on main
wtc AB-123/my-feature
# → creates branch AB-123/my-feature
# → creates ~/dev/myapp/.worktrees/AB-123/my-feature
# → cd's into it
```

### `wt` — Switch

fzf-based picker to `cd` into a worktree.

- Lists all worktrees via `git worktree list`, excluding the main worktree (repo root)
- fzf preview shows branch name and last commit
- `cd`s into selected worktree

```bash
wt
# fzf shows:
#   AB-123/my-feature   ~/dev/myapp/.worktrees/AB-123/my-feature
#   AB-456/other-thing  ~/dev/myapp/.worktrees/AB-456/other-thing
```

### `wtd [name]` — Delete

Removes a worktree and deletes its branch.

- With argument: deletes directly
- Without argument: fzf picker (same list as `wt`)
- Sequence:
  1. `git worktree remove <path>`
  2. `git branch -d <branch>` (clean delete)
  3. On failure: prompts "Run `git branch -D <branch>`? (y/n)" via existing `_dotfiles_prompt_git_branch_delete`
- Uses `_eval_script` for tmux-awareness (matches `gbd` pattern)

```bash
wtd                       # fzf picker
wtd AB-123/my-feature     # direct delete
```

## Merge Workflow

Cleanup is always manual. Typical flows:

```bash
# Local merge
cd ~/dev/myapp
git merge AB-123/my-feature
wtd AB-123/my-feature

# PR-based (push + merge on GitHub)
gpsu                      # from inside worktree
# merge PR
wtd AB-123/my-feature     # cleanup after
```

## Implementation

- All three functions go in `lib/commands.sh` alongside `gbd`
- Reuses `_dotfiles_prompt_git_branch_delete` and `_eval_script` helpers
- Shell functions (not scripts) so `cd` affects the current shell
