# gitconfig gh credential helper: cross-platform fix

## Problem

The `gitconfig` credential helper for `https://github.com` and `https://gist.github.com` was hardcoded to `/home/linuxbrew/.linuxbrew/bin/gh`, which breaks on macOS where Homebrew installs to `/opt/homebrew` or `/usr/local`.

## Decision

Replace hardcoded paths with `/usr/bin/env gh`, which searches `$PATH` at runtime and works on all platforms.

## Change

```ini
[credential "https://github.com"]
    helper = 
    helper = !/usr/bin/env gh auth git-credential

[credential "https://gist.github.com"]
    helper = 
    helper = !/usr/bin/env gh auth git-credential
```

The blank `helper =` line clears any system-level credential helper before setting `gh` as the sole helper.

## Rationale

`/usr/bin/env` is present at that exact path on both macOS and Linux and resolves binaries via `$PATH` — identical to how `#!/usr/bin/env bash` shebangs work. No platform detection or bootstrap coupling required.
