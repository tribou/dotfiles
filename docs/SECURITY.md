*How do we keep secrets safe? — environment variables, API key policy, and auth posture*

# Security

## API Keys and Secrets

- All environment variables containing secrets, tokens, or personal API keys MUST be stored in `~/.ssh/api_keys`.
- This file is sourced by `bash_profile` but is **never** checked into version control.
- Examples of keys stored here include `GIT_SIGNING_KEY` and third-party API tokens (e.g., `DIGITALOCEAN_API_TOKEN`).
- If `~/.ssh/api_keys` does not exist, the shell silently skips sourcing it — no error is raised, but secrets will be absent.

## Authentication Posture

- SSH keys are used for remote authentication where possible (GitHub uses SSH: `git@github.com`).

## Agent User Isolation

- The `agent/` user account runs LLM agents under a separate system user (`agent`) with a distinct git identity.
- The agent user has its own SSH key and shell profile, preventing cross-contamination with the primary user's credentials.
- The agent user profile sources `agent/overrides.sh` which sets a `[llm]` prompt prefix to visually distinguish agent sessions.
- The `agent/` directory files are **intentionally not sourced** by `bash_profile` or `lib/index.sh`.

## Version-Controlled Files

- No secrets, API keys, tokens, or personal credentials should ever be committed to this repository.
- The `.gitconfig` in this repo contains only non-sensitive configuration (aliases, signing settings, merge tool); email/name are set per-machine.
