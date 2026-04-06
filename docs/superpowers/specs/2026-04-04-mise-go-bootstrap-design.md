# mise Go Bootstrap Design

**Date:** 2026-04-04
**Scope:** Replace Homebrew-managed Go in `bootstrap.sh` with `mise`-managed Go, while keeping `gopls` installed and working after bootstrap.

## Background

The repository already uses `mise` in `bootstrap.sh` to install and manage Node and Ruby. Go is currently inconsistent with that approach in two ways:

- Homebrew installs `go` as part of the main package list.
- Bootstrap installs `gopls` directly with `go install`, assuming a working Go toolchain is already on `PATH`.

That creates two issues:

- Go does not follow the repo's current runtime-manager convention.
- The installed Go runtime can come from Homebrew instead of the same toolchain manager used for other languages.

The requested change is to make `mise` the source of truth for Go and keep `gopls` available after bootstrap.

## Goals

- Install Go via `mise` in `bootstrap.sh`.
- Track the moving stable Go release with `mise use -g go@latest`.
- Remove Homebrew as an installer for Go.
- Preserve existing `GOPATH=~/dev/go` behavior and related directory creation.
- Keep `gopls` installed and working after bootstrap.
- Add regression coverage for the Go runtime and `gopls`.

## Non-Goals

- Changing `GOPATH` layout or migrating away from GOPATH-based directories.
- Adding a broader manifest system for Go tools.
- Pinning Go to a fixed minor version.
- Refactoring unrelated bootstrap logic.

## Recommended Approach

Use `mise` as the only installer for the Go runtime and keep `gopls` as an explicit bootstrap-installed tool.

This is the smallest coherent change:

- It matches the current Node and Ruby setup.
- It removes the duplicate runtime source from Homebrew.
- It preserves existing editor support without introducing a new tool-management abstraction for a single Go binary.

## Design

### Runtime Installation

Update the existing `mise` setup block in `bootstrap.sh` so it installs Go alongside Node and Ruby:

```bash
mise use -g node@lts
MISE_RUBY_COMPILE=0 mise use -g ruby@3 || mise use -g ruby@3
mise use -g go@latest
```

This makes `mise` the only source of truth for the Go runtime during bootstrap.

### Homebrew Changes

Remove `go` from the `brew install` package list in `bootstrap.sh`.

After this change, bootstrap will no longer install a second Go toolchain via Homebrew. The only Go runtime bootstrap provisions will be the one installed by `mise`.

### Go Tool Installation

Keep `gopls` as a bootstrap-managed tool, but install it only after `mise` has been activated and `go` is available on `PATH`.

Recommended shape:

```bash
if [ -s "$(which go)" ] && [ ! -s "$(which gopls)" ]
then
  echo "Installing gopls"
  go install golang.org/x/tools/gopls@latest
fi
```

This preserves current behavior while making reruns cheaper and less noisy than reinstalling `gopls` on every bootstrap.

### Existing Go Environment

Keep the current GOPATH setup unchanged:

- `~/dev/go/pkg`
- `~/dev/go/src/github.com/tribou`
- `~/dev/go/src/bitbucket.org`
- `~/dev/go/src/github.com/rocksauce`
- `export GOPATH=~/dev/go`

Keep the current `bash_profile` exports unchanged as well so `GOPATH/bin` remains on `PATH`.

## Data Flow

1. Bootstrap ensures `mise` is installed and activated.
2. Bootstrap installs global runtimes with `mise`, including `go@latest`.
3. Shell `PATH` includes the `mise`-managed Go binary.
4. Bootstrap installs `gopls` with that Go toolchain if `gopls` is missing.
5. `goss.yaml` verifies both `go` and `gopls` are usable after bootstrap completes.

## Error Handling

- Only attempt `gopls` installation when `go` is actually available on `PATH`.
- Do not treat Homebrew as a fallback Go installer.
- If `mise` installation fails or `mise use -g go@latest` does not result in a usable `go` binary, bootstrap should not silently report success for the `gopls` step.

This keeps failure modes aligned with the new source of truth: either `mise` produced a working Go install, or Go tooling is unavailable and the verification layer catches it.

## Testing

Add `goss.yaml` command assertions for:

```yaml
"go version":
  exit-status: 0

"gopls version":
  exit-status: 0
```

These assertions cover the two user-visible guarantees this change needs to preserve:

- a working Go runtime exists after bootstrap
- `gopls` remains available for editor integration

## Files Expected To Change During Implementation

- `bootstrap.sh`
- `goss.yaml`

## Risks And Tradeoffs

- Using `go@latest` means bootstrap follows upstream Go releases automatically. That is intentional, but it trades reproducibility for lower maintenance.
- Keeping `gopls` installed via `go install` is slightly less declarative than a dedicated tool manifest, but it is simpler and sufficient for the current scope.
- Retaining GOPATH directories preserves compatibility with existing workflows, but it also keeps some older Go conventions in place. That is acceptable because changing them is out of scope for this work.
