# SSH Markdown Preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable `<space>o` in remote neovim+tmux over SSH to open the browser on the local machine via port forwarding.

**Architecture:** Two helper scripts + conditional neovim config + bootstrap/doctor integration. The remote script signals the local machine through a reverse SSH tunnel; the local helper opens the browser. Both are installed via bootstrap symlinks and validated by `just doctor`.

**Tech Stack:** bash, python3 stdlib, bats-core, neovim/vimscript

**Spec:** `docs/superpowers/specs/2026-05-24-ssh-markdown-preview-design.md`

---

## File Structure

| File | Responsibility |
|------|---------------|
| `scripts/dotfiles_remote_browser_open.sh` | Called by vim-markdown-composer as "browser"; forwards open request to local machine via reverse SSH tunnel |
| `scripts/dotfiles_local_browser_helper.sh` | Minimal HTTP server on localhost:15679; receives open requests and calls `webbrowser.open()` |
| `tests/dotfiles_remote_browser_open.bats` | Bats tests for remote browser open script |
| `tests/dotfiles_local_browser_helper.bats` | Bats tests for local browser helper |
| `init.vim` | Conditional `g:markdown_composer_*` variables when `$SSH_CLIENT` or `$SSH_TTY` is set |
| `bootstrap.sh` | Symlink new scripts to `~/.local/bin/` using existing `linkFileToHome` helper |
| `scripts/doctor.sh` | Validate new symlinks in `check_symlinks`; update `total_checks` |

---

## Task 1: Remote Browser Open Script (TDD)

**Files:**
- Create: `scripts/dotfiles_remote_browser_open.sh`
- Test: `tests/dotfiles_remote_browser_open.bats`

### Step 1: Write the failing test

Create `tests/dotfiles_remote_browser_open.bats`:

```bash
#!/usr/bin/env bats

setup() {
  load 'test_helper/common_setup'
  common_setup
  STUB_BIN="$(mktemp -d)"
}

teardown() {
  rm -rf "$STUB_BIN"
}

@test "remote_browser_open: calls curl with encoded URL" {
  # Stub curl to capture arguments and succeed
  cat > "$STUB_BIN/curl" <<'EOF'
#!/usr/bin/env bash
echo "$@" > "$CURL_CAPTURE"
exit 0
EOF
  chmod +x "$STUB_BIN/curl"

  export CURL_CAPTURE="$(mktemp)"
  export PATH="$STUB_BIN:$PATH"

  run bash -c "'$REPO_ROOT/scripts/dotfiles_remote_browser_open.sh' 'http://localhost:15678?page=foo bar'"

  [ "$status" -eq 0 ]
  local captured_args
  captured_args="$(cat "$CURL_CAPTURE")"
  [[ "$captured_args" == *"http://localhost:15679/open?url="* ]]
  [[ "$captured_args" == *"foo%20bar"* ]]
}

@test "remote_browser_open: prints error when curl fails" {
  # Stub curl to always fail
  cat > "$STUB_BIN/curl" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
  chmod +x "$STUB_BIN/curl"

  export PATH="$STUB_BIN:$PATH"

  run bash -c "'$REPO_ROOT/scripts/dotfiles_remote_browser_open.sh' 'http://localhost:15678'"

  [ "$status" -eq 1 ]
  [[ "$output" == *"local browser helper not running"* ]]
  [[ "$output" == *"dotfiles_local_browser_helper.sh"* ]]
}
```

### Step 2: Run test to verify it fails

```bash
just test-unit
```

Expected: FAIL with "dotfiles_remote_browser_open.sh: not found" or similar

### Step 3: Write minimal implementation

Create `scripts/dotfiles_remote_browser_open.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# This script is called by vim-markdown-composer as its "browser" over SSH.
# It forwards the browser-open request to the local machine via the reverse
# SSH tunnel (port 15679).

URL="$1"
ENCODED_URL=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$URL'''))")
curl -sf "http://localhost:15679/open?url=${ENCODED_URL}" >/dev/null 2>&1 || {
    echo "dotfiles: local browser helper not running on port 15679" >&2
    echo "Start it locally with: nohup dotfiles_local_browser_helper.sh >/dev/null 2>&1 &" >&2
    exit 1
}
```

Make it executable:

```bash
chmod +x scripts/dotfiles_remote_browser_open.sh
```

### Step 4: Run test to verify it passes

```bash
just test-unit
```

Expected: PASS for both tests

### Step 5: Commit

```bash
git add scripts/dotfiles_remote_browser_open.sh tests/dotfiles_remote_browser_open.bats
git commit -m "feat(ssh-markdown): add remote browser open script (dotfiles-7kw)"
```

---

## Task 2: Local Browser Helper (TDD)

**Files:**
- Create: `scripts/dotfiles_local_browser_helper.sh`
- Test: `tests/dotfiles_local_browser_helper.bats`

### Step 1: Write the failing test

Create `tests/dotfiles_local_browser_helper.bats`:

```bash
#!/usr/bin/env bats

setup() {
  load 'test_helper/common_setup'
  common_setup
}

teardown() {
  # Kill any leftover server process
  pkill -f "dotfiles_local_browser_helper" || true
}

@test "local_browser_helper: responds with 200 and opens browser on valid request" {
  # Start the helper in background on a test port
  local test_port=15680
  python3 "$REPO_ROOT/scripts/dotfiles_local_browser_helper.sh" "$test_port" &
  local server_pid=$!

  # Wait for server to start
  sleep 1

  # Make request and capture response
  run curl -sf "http://127.0.0.1:$test_port/open?url=http%3A//localhost%3A15678"

  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]

  kill "$server_pid" 2>/dev/null || true
}

@test "local_browser_helper: responds with 404 for unknown paths" {
  local test_port=15681
  python3 "$REPO_ROOT/scripts/dotfiles_local_browser_helper.sh" "$test_port" &
  local server_pid=$!

  sleep 1

  run curl -sf "http://127.0.0.1:$test_port/unknown"

  [ "$status" -eq 22 ]  # curl exit code 22 = HTTP 404

  kill "$server_pid" 2>/dev/null || true
}
```

### Step 2: Run test to verify it fails

```bash
just test-unit
```

Expected: FAIL with "dotfiles_local_browser_helper.sh: not found" or similar

### Step 3: Write minimal implementation

Create `scripts/dotfiles_local_browser_helper.sh`:

```python
#!/usr/bin/env python3
"""Minimal HTTP server to receive browser-open requests from remote SSH sessions.

Runs on localhost:15679. When it receives /open?url=..., it opens the URL in the
local default browser.

Usage:
    dotfiles_local_browser_helper.sh [PORT]

RAM usage: ~5-8 MB idle (Python stdlib only, no external dependencies).
"""
import http.server
import socketserver
import sys
import urllib.parse
import webbrowser

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 15679


class SilentHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/open?'):
            query = urllib.parse.urlparse(self.path).query
            params = urllib.parse.parse_qs(query)
            if 'url' in params:
                webbrowser.open(params['url'][0], new=2)
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'ok\n')
                return
        self.send_response(404)
        self.end_headers()
        self.wfile.write(b'not found\n')

    def log_message(self, format, *args):
        pass  # Suppress all request logging


if __name__ == '__main__':
    with socketserver.TCPServer(("127.0.0.1", PORT), SilentHandler) as httpd:
        httpd.serve_forever()
```

Make it executable:

```bash
chmod +x scripts/dotfiles_local_browser_helper.sh
```

### Step 4: Run test to verify it passes

```bash
just test-unit
```

Expected: PASS for both tests

### Step 5: Commit

```bash
git add scripts/dotfiles_local_browser_helper.sh tests/dotfiles_local_browser_helper.bats
git commit -m "feat(ssh-markdown): add local browser helper (dotfiles-7kw)"
```

---

## Task 3: Neovim Configuration

**Files:**
- Modify: `init.vim:432-434`

### Step 1: Add SSH conditional config

In `init.vim`, after the existing markdown-composer config block (around line 432-434), add:

```vim
" SSH markdown preview support
" When connected via SSH, bind composer to a fixed port and route browser opens
" through the reverse SSH tunnel to the local machine.
if exists('$SSH_CLIENT') || exists('$SSH_TTY')
  let g:markdown_composer_port = 15678
  let g:markdown_composer_browser = expand('~/.local/bin/dotfiles_remote_browser_open.sh')
  let g:markdown_composer_open_browser = 1
endif
```

### Step 2: Verify init.vim syntax

```bash
bashcheck init.vim || true
```

Note: `bashcheck` validates bash syntax; for vimscript, manual review is sufficient. Verify there are no vim syntax errors by scanning the file.

### Step 3: Commit

```bash
git add init.vim
git commit -m "feat(ssh-markdown): add SSH conditional composer config (dotfiles-7kw)"
```

---

## Task 4: Bootstrap Integration

**Files:**
- Modify: `bootstrap.sh`

### Step 1: Add symlink calls

In `bootstrap.sh`, after the existing `linkFileToHome` calls (around line 163, after the coc-settings.json line), add:

```bash
# Symlink helper scripts for SSH markdown preview
linkFileToHome "scripts/dotfiles_remote_browser_open.sh" ".local/bin/dotfiles_remote_browser_open.sh"
linkFileToHome "scripts/dotfiles_local_browser_helper.sh" ".local/bin/dotfiles_local_browser_helper.sh"
```

### Step 2: Verify bootstrap syntax

```bash
bashcheck bootstrap.sh
```

Expected: No output (success)

### Step 3: Commit

```bash
git add bootstrap.sh
git commit -m "feat(ssh-markdown): symlink helper scripts in bootstrap (dotfiles-7kw)"
```

---

## Task 5: Doctor Validation

**Files:**
- Modify: `scripts/doctor.sh`

### Step 1: Add new symlinks to check_symlinks

In `scripts/doctor.sh`, in the `check_symlinks` default array (around line 28-32), add two entries after `"~/.config/nvim/coc-settings.json~coc-settings.json"`:

```bash
            "~/.local/bin/dotfiles_remote_browser_open.sh~scripts/dotfiles_remote_browser_open.sh"
            "~/.local/bin/dotfiles_local_browser_helper.sh~scripts/dotfiles_local_browser_helper.sh"
```

### Step 2: Update total_checks

In `scripts/doctor.sh`, update `total_checks` from `23` to `25` (line 148):

```bash
    local total_checks=25  # 15 symlinks + 3 skills dirs + 7 tools
```

### Step 3: Write failing test for new doctor entries

In `tests/doctor.bats`, update the two `main` tests that hardcode the summary line:

- In `@test "main exits 0 when all checks pass"`, update the `symlinks` array to include:

```bash
    local symlinks=(
        "~/.bash_profile~bash_profile"
        "~/.vimrc~init.vim"
        "~/.gitconfig~gitconfig"
        "~/.zshrc~zshrc"
        "~/.tmux.conf~tmux/tmux-conf"
        "~/.default-node-packages~default-node-packages"
        "~/.default-gems~default-gems"
        "~/.default-python-packages~default-python-packages"
        "~/.gnupg/gpg-agent.conf~gpg-agent-conf"
        "~/.config/nvim/init.vim~init.vim"
        "~/.config/alacritty/alacritty.toml~alacritty.toml"
        "~/.config/mise/config.toml~mise-config.toml"
        "~/.config/nvim/coc-settings.json~coc-settings.json"
        "~/.local/bin/dotfiles_remote_browser_open.sh~scripts/dotfiles_remote_browser_open.sh"
        "~/.local/bin/dotfiles_local_browser_helper.sh~scripts/dotfiles_local_browser_helper.sh"
    )
```

And change the assertion from `"doctor: 23/23 checks passed (0 failures)"` to `"doctor: 25/25 checks passed (0 failures)"`.

- In `@test "main exits 1 when checks fail"`, change the assertion from `"doctor: 0/23 checks passed (23 failures)"` to `"doctor: 0/25 checks passed (25 failures)"`.

### Step 4: Run test to verify it fails

```bash
just test-unit
```

Expected: FAIL with "doctor: 23/23" not matching or missing symlink checks

### Step 5: Verify fix and run tests

```bash
just test-unit
```

Expected: PASS for all doctor tests

### Step 6: Commit

```bash
git add scripts/doctor.sh tests/doctor.bats
git commit -m "feat(ssh-markdown): validate new symlinks in doctor (dotfiles-7kw)"
```

---

## Task 6: Run Full Test Suite

### Step 1: Run unit tests

```bash
just test-unit
```

Expected: All bats tests pass

### Step 2: Run full test suite in Docker

```bash
just test
```

Expected: Docker tests pass (goss + bats)

### Step 3: Commit

If any fixes were needed:

```bash
git add -A
git commit -m "fix(ssh-markdown): address test failures (dotfiles-7kw)"
```

---

## Task 7: Manual Validation Checklist

Perform these steps on an actual SSH session before closing the issue.

### Prerequisites
- [ ] SSH config has `LocalForward 15678 localhost:15678` and `RemoteForward 15679 localhost:15679`
- [ ] `dotfiles_local_browser_helper.sh` is running on the local machine
- [ ] `bootstrap.sh` has been run on the remote machine

### Steps
1. [ ] SSH into remote with port forwarding enabled
2. [ ] Open a markdown file in neovim (`nvim test.md`)
3. [ ] Press `<space>o`
4. [ ] Verify browser opens on the **local** machine at `http://localhost:15678`
5. [ ] Verify live preview updates when editing the markdown file
6. [ ] Press `<space>o` again to toggle off
7. [ ] Verify local editing (non-SSH) still works normally

---

## Rollout

After all tasks and manual validation are complete:

```bash
bd update dotfiles-7kw --status=done
```

Push to remote:

```bash
git pull --rebase
bd dolt push
git push
git status  # MUST show "up to date with origin"
```
