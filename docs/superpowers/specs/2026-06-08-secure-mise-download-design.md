# Secure Mise Download Design

## Goal

Resolve a security/reliability issue where `mise` (the version manager) is downloaded and piped directly to a shell without fail-fast or verification flags.

## Design

We will modify the insecure `curl` calls to install `mise` to use safe, secure, and quiet options (`-fsSL`):

- **Files to Modify:**
  - `bootstrap.sh`
  - `Dockerfile`

- **Changes:**
  - Update `curl https://mise.run | sh` to `curl -fsSL https://mise.run | sh`
  - This ensures:
    - HTTP or connection failures prevent executing incomplete scripts (`-f` / `--fail`).
    - Redirects are automatically followed (`-L` / `--location`).
    - Progress bars and headers do not clutter output logs (`-s` / `--silent`, `-S` / `--show-error`).

## Why

1. **Safety/Reliability**: Running `curl` without `-f` means that if the download fails or is truncated, the shell executes whatever content has been downloaded (or error HTML). Piping an incomplete script to a shell interpreter can result in executing partial commands, leading to unpredictable system states.
2. **Robustness**: If the domain or server hosting `mise.run` changes redirects, curl without `-L` will download redirect HTML instead of the script, causing the bootstrap process to fail or break silently.
3. **Consistency**: Other tools in `bootstrap.sh` (Rust, Homebrew, Vim-Plug) already use these secure flags.
