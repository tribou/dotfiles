# Bash Testing Strategy Design

## Decision

Adopt **bats-core** as the single unit test framework. Use it in two contexts:
1. **Local unit tests** for pure logic functions (fast, no Docker)
2. **Docker integration tests** for environment/plugin/keymap assertions (alongside existing goss)

No second framework. No mocking of external commands — extract testable logic instead.

## Framework Setup

### Directory Structure

```
tests/
  test_helper/
    bats-core/        # git submodule
    bats-support/     # git submodule
    bats-assert/      # git submodule
    common_setup.bash # shared setup: source lib/_shared.sh, lib/commands.sh
  grep_ticket_number.bats       # migrated from test_grep_ticket_number.sh
  commit_message.bats           # migrated from test_commit_message.sh
  clipboard.bats                # copy_to_clipboard / paste_from_clipboard
  npm_detection.bats            # npm-install, npm-run detection logic
  use_local_if_available.bats   # useLocalIfAvailable
  platform_guards.bats          # restart-docker, OS-conditional logic
  histgrep.bats                 # regex/prefix parsing
  eval_script.bats              # tmux detection branch
  integration/
    nvim_health.bats            # runs in Docker only
    nvim_keymaps.bats           # runs in Docker only
    tmux_environment.bats       # runs in Docker only
    bash_profile.bats           # runs in Docker only
    bootstrap_idempotency.bats  # runs in Docker only
```

### Installation

bats-core, bats-support, and bats-assert as git submodules under `tests/test_helper/`.

### Justfile Updates

```
test-unit  → ./tests/test_helper/bats-core/bin/bats tests/*.bats
test       → Docker: bootstrap → goss validate → bats tests/integration/*.bats
dev        → Interactive Docker (unchanged)
```

## Unit Tests (bats-core, local)

### Tier 1 — Migrate Existing (30 cases)

| File | Function | Existing Cases |
|---|---|---|
| `grep_ticket_number.bats` | `_dotfiles_grep_ticket_number` | 24 |
| `commit_message.bats` | `_dotfiles_commit_message` | 6 |

### Tier 2 — High Value, Easy to Test

| File | Function(s) | What to Test | Motivated By |
|---|---|---|---|
| `clipboard.bats` | `copy_to_clipboard`, `paste_from_clipboard` | OS detection returns correct command | Broke twice (xclip selection, pbcopy on Linux) |
| `npm_detection.bats` | `npm-install`, `npm-run` detection logic | pnpm-lock.yaml > yarn.lock > bun.lock > npm fallback | Core workflow, 4 code paths, zero tests |
| `use_local_if_available.bats` | `useLocalIfAvailable` | Local bin exists > uses it; missing > npx fallback | Path resolution logic is testable |
| `platform_guards.bats` | `restart-docker` OS guard | macOS-only, error on Linux | Broke on Linux |
| `histgrep.bats` | `histgrep` regex/prefix logic | Hostname with colons, prefix extraction | Broke due to regex edge case |

### Tier 3 — Extract Logic First

| File | Function | Extractable Logic | Notes |
|---|---|---|---|
| `eval_script.bats` | `_eval_script` | tmux detection branch (`$TMUX` set or not) | Two code paths |
| (future) | `search` | Exclusion pattern list construction | Currently inline |
| (future) | `supabase-profile` | TSV parsing logic | Complex string parsing |
| (future) | `bashcheck` | File filtering logic | *.sh detection |

## Integration Tests (bats-core, Docker)

### Neovim Health & Plugins

| Assertion | Method |
|---|---|
| checkhealth exits clean | `nvim --headless +checkhealth +qall`, parse for ERROR lines |
| All plugins installed | List expected dirs in `~/.local/share/nvim/plugged/` |
| `:PlugStatus` no errors | `nvim --headless -c 'PlugStatus' -c 'qall'` capture output |
| CoC extensions installed | Check `~/.config/coc/extensions/node_modules/` |
| No startup errors (no E-codes) | `nvim --headless -c 'messages' -c 'qall'` |
| ALE loads for key filetypes | Open `.ts` file, check `ALEInfo` output |

### Neovim Keymaps

| Assertion | Method |
|---|---|
| Leader key mappings exist | `nvim --headless -c 'verbose map <leader>' -c 'qall'` |
| No keymap conflicts per mode | Parse `:map` output for duplicates |
| Critical maps present (e.g. `<C-p>`) | Assert in `:map` output |

### Tmux Environment

| Assertion | Method |
|---|---|
| Correct prefix (`C-f`) | `tmux start-server && tmux show-options -g prefix` |
| Plugins loaded | Check `~/.tmux/plugins/` dirs |
| Plugin-specific bindings exist | `tmux list-keys` grep for resurrect, yank bindings |
| Key bindings present (split, resize) | `tmux list-keys` assert specific entries |
| Status bar renders | `tmux display-message -p '#{status-left}'` |

### Shell Environment

| Assertion | Method |
|---|---|
| bash_profile sources without errors | Source in subshell, check exit code and stderr |
| Bootstrap idempotency | Run bootstrap.sh twice, no errors on second run |

## Infrastructure Assertions (goss, Docker)

Existing goss.yaml stays for what it does well. Expand to ~20-25 assertions:

| Current (~12) | Add |
|---|---|
| tmux, git, nvim, node versions | Homebrew PATH presence |
| DOTFILES env var | DEVPATH, GOPATH set |
| vim source files (6) | Symlinks created correctly (.bash_profile, .vimrc, .gitconfig) |
| tmux plugins (7) | nvim plugged directory populated |
| vim-plug autoload | CoC extensions directory exists |
| bootstrap marker file | |

## What We're NOT Doing

- No ShellSpec, Bach, shUnit2, or any second test framework
- No mocking external commands — extract logic into pure functions instead
- No tests for trivial wrappers (aliases, one-line git wrappers like `f`, `ga`, `s`)
- No performance tests (shell startup time) — noted for future
- No tests for interactive fzf selection flows

## Implementation Order

1. Add bats-core, bats-support, bats-assert as git submodules
2. Create `tests/test_helper/common_setup.bash`
3. Migrate existing 30 test cases to bats format
4. Update justfile `test-unit` target
5. Delete old test files and custom assert framework
6. Add Tier 2 unit tests (clipboard, npm detection, platform guards, histgrep)
7. Add Tier 3 unit tests (extract logic, then test)
8. Add Docker integration bats tests (nvim, tmux, shell env)
9. Expand goss.yaml with additional infrastructure assertions
