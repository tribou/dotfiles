# Bash to Zsh Migration Plan

## Overview
Complete migration from bash to zsh with full feature parity. Remove bash support entirely.

**Scope**:
- Convert bash_profile (358 lines) → zshrc
- Convert 11 lib files (~1,500+ lines)
- Update bootstrap.sh, init.vim
- 60+ bash-specific syntax issues
- 150+ aliases, 30+ custom functions

**Strategy**: Atomic migration (all-at-once, not incremental)

---

## Phase 1: Foundation Files (Critical Dependencies)

### 1.1 Create New zshrc
**File**: `/Users/tribou/dev/dotfiles/zshrc`

**Actions**:
1. Replace entire file content (convert all 358 lines from bash_profile)
2. Fix hardcoded username: `/Users/aaron.tribou/.sdkman` → `$HOME/.sdkman`
3. Convert bash-specific features:

```zsh
# Shell declaration
export SHELL=/bin/zsh

# Completion (replaces bind commands)
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
setopt AUTO_LIST LIST_AMBIGUOUS

# Globbing (replaces shopt)
setopt GLOB_DOTS

# History settings
export HISTSIZE=10000
export SAVEHIST=10000
setopt HIST_IGNORE_SPACE
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt HIST_VERIFY

# Prompt with precmd (replaces PROMPT_COMMAND)
setopt PROMPT_SUBST
export PS1='%F{blue}%1~ $([ -n "$HAS_NVM" ] && nvm current) $(get_git_location) > %f'

precmd_functions+=(read_node_version)
[ "$TERM_PROGRAM" = "iTerm.app" ] && precmd_functions+=(set_badge)

# AWS completion
autoload -Uz bashcompinit && bashcompinit
command -v aws_completer >/dev/null 2>&1 && complete -C aws_completer aws

# OrbStack zsh support
[ -f "$HOME/.orbstack/shell/init.zsh" ] && source "$HOME/.orbstack/shell/init.zsh"
```

4. Keep all PATH configurations, tool initializations (NVM, pyenv, rbenv, jenv, etc.)
5. Source lib files at end: `. "$DOTFILES/lib/index.sh"`

**Critical**: Line 335 sourcing must happen after all function definitions

---

### 1.2 Convert lib/index.sh
**File**: `/Users/tribou/dev/dotfiles/lib/index.sh`

**Change**:
```zsh
#!/bin/zsh

function source_lib()
{
  # ZSH: Use glob with array, remove index.sh
  local SOURCE_FILES=($DOTFILES/lib/*(N))
  SOURCE_FILES=(${SOURCE_FILES:#*index.sh})

  for file in "${SOURCE_FILES[@]}"
  do
    . "$file"
  done
}

source_lib
unset -f source_lib
unset file
```

---

### 1.3 Convert lib/_shared.sh
**File**: `/Users/tribou/dev/dotfiles/lib/_shared.sh`

**Changes**:
1. Change shebang: `#!/bin/zsh`
2. Replace backticks with `$()` (lines 13-14, 41-42)
3. Pattern matching: `[[ "$OSTYPE" == "darwin"* ]]` → `[[ "$OSTYPE" = darwin* ]]`
4. Test all parameter expansions work in zsh

---

## Phase 2: Lib Files (Prioritized Order)

### 2.1 lib/fzf.sh
**Changes**:
- Line 31: `IFS=$'\n' out=("...")` → `out=("${(@f)$(...)}")`
- HERE-string `<<<` works in zsh but test array access
- Alternative: Use array indices `${out[1]}`, `${out[2]}`

### 2.2 lib/remind.sh
**Changes**:
- Replace backticks (lines 13-14): `` `tput lines` `` → `$(tput lines)`
- Array arithmetic (line 27): `MESSAGE_LINE_COUNTS[$((++N))]` → use `((N++))` first, then assign
- Test while loop with HERE-string works

### 2.3 lib/replace.sh
**Changes**:
- Backticks → `$()` (line 22)
- `read -d null` works in zsh (test line 135)
- HERE-string works (line 138)

### 2.4 lib/init_project.sh
**Changes**:
- Declare arrays: `local -a options` before assignment
- `select` statement works same in zsh
- Test sed operations

### 2.5 lib/command_reference.sh
**Changes**:
- `read -r -d ''` with HERE-doc: Convert to direct assignment or test compatibility
- Replace backticks: `` `tput sgr0` `` → `$(tput sgr0)`

### 2.6 lib/commands.sh (LARGEST - 866 lines)
**Critical changes**:
1. Pattern matching: `[[ "$var" == "pattern"* ]]` → `[[ "$var" = pattern* ]]`
2. Read prompts: `read -p "prompt" var` → `read "var?prompt"`
3. Parameter expansion (line 89, 182): Test native zsh expansion
4. Aliases:
   - `alias setdotglob='setopt GLOB_DOTS'`
   - `alias unsetdotglob='unsetopt GLOB_DOTS'`
   - `alias sprofile='. ~/.zshrc'`
5. IFS with read (line 588): Test compatibility

**Test each function group**:
- Git: c, cn, co, f, ga, gpsu, gbd, merge
- NPM: npm-run, npm-install, nu, ninfo
- AWS: aws-profile, aws-set-current-account-id
- Supabase: supabase-profile
- Docker: da, ds, dminit
- Tmux layouts: tmux-large, tmux-small, tmux-xl
- Search: search, histgrep

### 2.7 lib/sizes.sh, lib/curl_it.sh, lib/notify.sh
**Changes**:
- Change shebang: `#!/bin/zsh`
- Test but mostly POSIX-compliant

---

## Phase 3: Supporting Files

### 3.1 Update bootstrap.sh
**File**: `/Users/tribou/dev/dotfiles/bootstrap.sh`

**Remove** (lines 53-55):
```bash
# DELETE THESE LINES:
backupFile ".bash_profile"
linkFileToHome bash_profile .bash_profile
```

**Keep** zshrc symlinking (lines 65-67) - already present

---

### 3.2 Update init.vim
**File**: `/Users/tribou/dev/dotfiles/init.vim`

**Replace** line 249:
```vim
" Shell-agnostic configuration
if filereadable(expand('~/.ssh/api_keys'))
  if $SHELL =~ 'zsh'
    set shell=/bin/zsh\ -c\ 'source\ ~/.ssh/api_keys\ &&\ exec\ zsh'
  elseif $SHELL =~ 'bash'
    set shell=/bin/bash\ --rcfile\ ~/.ssh/api_keys
  else
    set shell=/bin/zsh
  endif
else
  set shell=$SHELL
endif
```

---

## Phase 4: Testing

### 4.1 Create Test Script
**File**: `/Users/tribou/dev/dotfiles/tests/test-zsh-migration.sh`

```bash
#!/bin/zsh

echo "=== ZSH Migration Tests ==="

# Test environment variables
echo "DOTFILES: ${DOTFILES:-FAIL}"
echo "SHELL: $SHELL"

# Test tool initialization
nvm current
node --version

# Test custom functions exist
type c co ga gpsu npm-run

# Test aliases
alias | grep -E "(sprofile|setdotglob|ll)"

# Test prompt
get_git_location

# Test history
setopt | grep HIST

# Test completion
echo $fpath | head -3

# Test glob
setopt | grep GLOB
```

### 4.2 Manual Testing Checklist
- [ ] `zsh` starts without errors
- [ ] `echo $PATH` contains homebrew, nvm, pyenv, rbenv
- [ ] `nvm current` shows version
- [ ] `type c` shows function
- [ ] Git commit with `c "message"` auto-prefixes ticket
- [ ] `co` with fzf shows branches
- [ ] `npm-run` with fzf shows scripts
- [ ] `tmux-small` creates layout
- [ ] `search "pattern"` works
- [ ] Aliases work: `ll`, `gs`, `v`

---

## Phase 5: Migration Execution Order

**Day 1: Foundation**
1. Backup: `tar -czf ~/dotfiles-backup-$(date +%Y%m%d).tar.gz ~/dev/dotfiles`
2. Create new zshrc (from bash_profile)
3. Convert lib/index.sh
4. Convert lib/_shared.sh
5. Test: `zsh -c 'source zshrc'`

**Day 2: Lib Batch 1**
6. Convert lib/fzf.sh
7. Convert lib/remind.sh
8. Convert lib/sizes.sh, lib/curl_it.sh, lib/notify.sh
9. Test each individually

**Day 3: Lib Batch 2**
10. Convert lib/replace.sh
11. Convert lib/command_reference.sh
12. Convert lib/init_project.sh

**Day 4: Commands (Heavy)**
13. Convert lib/commands.sh (2-4 hours)
14. Test function groups
15. Test all 150+ aliases

**Day 5: Integration**
16. Update bootstrap.sh
17. Update init.vim
18. Create test script
19. Full integration test

**Day 6: Validation**
20. Run zsh as daily driver
21. Test all workflows
22. Document issues

**Day 7: Finalize**
23. Remove/archive bash_profile
24. Update README.md
25. Update CLAUDE.md

---

## Rollback Plan

If migration fails:
```bash
# Restore bash
chsh -s /bin/bash
cp ~/.bash_profile.backup ~/.bash_profile
source ~/.bash_profile

# Revert dotfiles
cd ~/dev/dotfiles
git checkout main  # or previous branch
./bootstrap.sh
```

---

## Breaking Changes

**Users must**:
1. Run `chsh -s /bin/zsh` to switch default shell
2. Open new terminal window (or `exec zsh`)
3. No bash_profile support - zsh only

**Behavior changes**:
- Tab completion shows menu (navigate with arrows)
- `*` matches hidden files by default (GLOB_DOTS)
- History timestamps in different format
- OrbStack uses init.zsh not init.bash

---

## Critical Files

1. **zshrc** - Core config (358 lines from bash_profile)
2. **lib/index.sh** - Dynamic sourcing (array issues)
3. **lib/commands.sh** - 866 lines, 30+ functions, 150+ aliases
4. **lib/_shared.sh** - Foundation helpers
5. **lib/fzf.sh** - FZF integration (complex array/IFS issues)
6. **bootstrap.sh** - Installation script
7. **init.vim** - Shell configuration

---

## Estimated Effort

- **Total lines**: ~2,500
- **Time**: 26-30 hours over 7 days
- **Complexity**: High (60+ bash-specific patterns)
- **Risk**: Medium (atomic migration, good rollback)
