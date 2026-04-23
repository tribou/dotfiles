# Design: Add bun to bootstrap.sh via mise

## Summary

Add bun as a mise-managed tool so it is automatically installed during bootstrap on both macOS and Linux.

## Changes

### 1. `mise-config.toml`

Add `bun = "latest"` to the `[tools]` section alongside node, ruby, and go.

```toml
[tools]
node = "lts"
ruby = "3"
go = "latest"
bun = "latest"
```

### 2. `bootstrap.sh`

Update the existing mise install line to include bun:

```bash
# before
mise install node go

# after
mise install node go bun
```

Ruby retains its separate install block with the `MISE_RUBY_COMPILE=0` fallback — this change does not touch that logic.

### 3. `bash_profile`

No change. The existing `~/.bun/bin` PATH guard is a harmless no-op when bun is managed by mise, and acts as a safety net for legacy installs.

## Out of Scope

- Removing the `~/.bun/bin` PATH entry from bash_profile
- Installing any bun global packages during bootstrap
