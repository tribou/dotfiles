# Agent GitHub Token Design

**Date:** 2026-04-05
**Problem:** SSH deploy keys are per-repo — the agent can only read/write a single GitHub repo at a time.
**Solution:** Replace SSH-based GitHub auth with `gh` CLI + fine-grained personal access token (PAT) via HTTPS.

## Overview

- Agent user authenticates to GitHub via HTTPS + `gh` credential helper
- Token is manually provisioned once per machine via `gh auth login --with-token`
- Fine-grained PATs scope access to only the repos the agent needs
- SSH key is retained for server SSH auth (not used for GitHub)

## Changes

### `bootstrap.sh`
- Add `gh` to the cross-platform `brew install` block (alongside `git`, `jq`, etc.)

### `agent/setup-user.sh`

**Remove:**
- `write_ssh_config` — no longer need GitHub/GitLab SSH identity entries
- `print_public_key` — replaced by `print_gh_auth_instructions`

**Update `write_gitconfig`:**
- Remove `[core] sshCommand` override
- Add URL rewrites so SSH remote URLs are transparently handled via HTTPS:
  ```
  [url "https://github.com/"]
    insteadOf = git@github.com:
  [url "https://gitlab.com/"]
    insteadOf = git@gitlab.com:
  ```

**Add `symlink_main_user_bin gh`** in main section (alongside `claude`, `opencode`).

**Add `setup_gh_credential_helper`:**
```bash
setup_gh_credential_helper() {
  log "Configuring gh credential helper for agent user"
  sudo -u "$AGENT_USER" gh auth setup-git
}
```
Called after `symlink_main_user_bin gh` in main flow.

**Add `print_gh_auth_instructions`:**
```
================================================================
NEXT STEP: Authenticate agent with GitHub using a fine-grained PAT:
  sudo -u agent gh auth login --with-token <<< "YOUR_FINE_GRAINED_PAT"
Token rotation: re-run the above command with a new token at any time.
================================================================
```

## Fine-Grained PAT Configuration

Create at: GitHub → Settings → Developer Settings → Fine-grained tokens

| Setting | Value |
|---------|-------|
| Resource owner | your account or org |
| Repository access | Selected repositories (only what agent needs) |
| Contents | Read and write |
| Metadata | Read (auto-required) |
| Pull requests | Read and write (if agent opens/merges PRs) |
| Workflows | Read and write (if agent touches `.github/workflows`) |

Token rotation requires only re-running `gh auth login --with-token` — no other config changes.
