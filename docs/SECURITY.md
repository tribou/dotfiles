*How do we keep secrets safe? — environment variables, API key policy, and auth posture*

# Security

## API Keys and Secrets
- All environment variables containing secrets, tokens, or personal API keys MUST be stored in `~/.ssh/api_keys`.
- This file is sourced by `bash_profile` but is NEVER checked into version control.
- Examples of keys stored here include `GIT_SIGNING_KEY` and third-party API tokens.

## Authentication Posture
- SSH keys are used for remote authentication where possible.
- GPG signing is strictly required for Git commits. If `GIT_SIGNING_KEY` is missing, the system will explicitly warn the user.
