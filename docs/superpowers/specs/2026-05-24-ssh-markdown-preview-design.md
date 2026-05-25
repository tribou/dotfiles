# SSH Markdown Preview: Open Local Browser from Remote Neovim+tmux

## Issue

- `dotfiles-7kw`

## Problem Statement

When editing markdown files in neovim inside tmux on a remote server accessed via SSH,
pressing `<space>o` (mapped to `ComposerToggle()`) starts the `vim-markdown-composer`
HTTP server on the **remote** machine but fails to open the browser because there is no
 graphical environment on the remote. The desired behavior is for the browser to open on
the **local** machine with a live preview of the remote markdown file.

## Goals

1. `<space>o` in markdown files works identically whether editing locally or over SSH
2. The browser opens on the **local** machine when working over SSH
3. The markdown preview server runs on the **remote** machine (where the file lives)
4. The solution is opt-in per SSH session (only activates when `$SSH_CLIENT` or `$SSH_TTY` is set)
5. The local helper process uses minimal RAM

## Non-Goals

1. Support for non-SSH remote connections (e.g., mosh, plain telnet)
2. Automatic SSH config modification (documented manual steps instead)
3. Persistent background services installed via systemd/launchd

## Architecture

```
┌─────────────────────────────┐         ┌─────────────────────────────┐
│      LOCAL MACHINE          │         │      REMOTE MACHINE         │
│                             │  SSH    │                             │
│  ┌─────────────────────┐   │ Tunnel  │  ┌─────────────────────┐    │
│  │ Browser (Firefox)   │◄──┼─────────┼──┤ markdown-composer   │    │
│  │ http://localhost:   │   │ 15678   │  │ server (port 15678) │    │
│  │       15678         │   │         │  └─────────────────────┘    │
│  └─────────────────────┘   │         │            ▲                  │
│            ▲               │         │            │ RPC              │
│            │               │         │  ┌─────────────────────┐    │
│            │               │         │  │  neovim             │    │
│            │               │         │  │  <space>o ──────────┘    │
│  ┌─────────────────────┐   │         │  └─────────────────────┘    │
│  │ dotfiles-local-     │   │         │            │                │
│  │ browser-helper      │◄──┼─────────┼────────────┘                │
│  │ (port 15679)        │   │ 15679   │                               │
│  └─────────────────────┘   │ reverse │                               │
│            ▲               │ forward │                               │
│            │ curl          │         │                               │
│  ┌─────────────────────┐   │         │                               │
│  │ dotfiles-remote-    │───┼─────────┼───────────────────────────────┘
│  │ browser-open        │   │         │
│  │ (called as browser  │   │         │
│  │  by composer)      │   │         │
│  └─────────────────────┘   │         │
└─────────────────────────────┘         └─────────────────────────────┘
```

## Components

### 1. SSH Config (manual step, not in dotfiles)

Add port forwarding to the relevant `Host` entries in `~/.ssh/config`:

```
Host myremote
    HostName myremote.example.com
    User myuser
    # Forward remote composer's HTTP server to local machine
    LocalForward 15678 localhost:15678
    # Reverse forward: remote can signal local machine to open browser
    RemoteForward 15679 localhost:15679
```

The fixed port (`15678`) is used so the neovim config can predictably set
`g:markdown_composer_port`.

### 2. Remote Browser Open Script

`scripts/dotfiles-remote-browser-open`:

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
    echo "Start it locally with: nohup dotfiles-local-browser-helper >/dev/null 2>&1 &" >&2
    exit 1
}
```

This script is symlinked to `~/.local/bin/` by `bootstrap.sh`.

### 3. Local Browser Helper

`scripts/dotfiles-local-browser-helper`:

```python
#!/usr/bin/env python3
"""Minimal HTTP server to receive browser-open requests from remote SSH sessions.

Runs on localhost:15679. When it receives /open?url=..., it opens the URL in the
local default browser.

RAM usage: ~5-8 MB idle (Python stdlib only, no external dependencies).
"""
import http.server
import socketserver
import urllib.parse
import webbrowser

PORT = 15679


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

This script is symlinked to `~/.local/bin/` by `bootstrap.sh` on **both** local and
remote machines. It only needs to be running on the **local** machine.

### 4. Neovim Configuration

Add conditional configuration to `init.vim` (or a sourced file):

```vim
" SSH markdown preview support
" When connected via SSH, bind composer to a fixed port and route browser opens
" through the reverse SSH tunnel to the local machine.
if exists('$SSH_CLIENT') || exists('$SSH_TTY')
  let g:markdown_composer_port = 15678
  let g:markdown_composer_browser = expand('~/.local/bin/dotfiles-remote-browser-open')
  let g:markdown_composer_open_browser = 1
endif
```

This ensures the composer server binds to `localhost:15678` (which is forwarded
to the local machine via `LocalForward`), and the browser open command sends a
request back through the reverse tunnel (`RemoteForward 15679`).

### 5. Bootstrap Integration

In `bootstrap.sh`, add symlinks for the new scripts:

```bash
# Symlink helper scripts for SSH markdown preview
mkdir -p ~/.local/bin
for script in dotfiles-remote-browser-open dotfiles-local-browser-helper; do
  if [ -f "$DOTFILES/scripts/$script" ]; then
    rm -f "$HOME/.local/bin/$script"
    ln -sf "$DOTFILES/scripts/$script" "$HOME/.local/bin/$script"
    chmod +x "$HOME/.local/bin/$script"
  fi
done
```

## Data Flow

1. User presses `<space>o` in a markdown file inside remote neovim+tmux
2. `ComposerToggle()` starts the composer server on `localhost:15678`
3. The server is accessible locally on the user's machine via `LocalForward 15678`
4. `ComposerToggle()` then calls `ComposerOpen`, which sends an `open_browser` RPC to the composer
5. The composer spawns the configured browser command: `~/.local/bin/dotfiles-remote-browser-open http://localhost:15678`
6. The remote script curls `http://localhost:15679/open?url=...` through the reverse tunnel
7. The local helper receives the request and calls `webbrowser.open()`
8. The local browser opens `http://localhost:15678` (the forwarded composer server)
9. Live markdown updates flow over `LocalForward 15678` via WebSocket

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Local helper not running | Remote script prints error to neovim message line with instructions to start it |
| SSH tunnel not configured | Composer binds to `localhost:15678` but browser open fails; user sees error message |
| Port 15678 already in use | Composer fails to start; standard neovim error output |
| Port 15679 already in use | Local helper fails to start; user sees "Address already in use" |
| curl not available on remote | Remote script fails with "command not found"; documented dependency |

## Security Considerations

1. Both ports (`15678`, `15679`) bind to `127.0.0.1` only — no external network exposure
2. The reverse tunnel (`RemoteForward`) only accepts connections from the authenticated SSH session
3. No authentication is required on the local helper because it's only reachable via the SSH tunnel
4. The `webbrowser.open()` call uses the default system browser handler; no arbitrary command execution

## Testing

1. **Unit test** for `dotfiles-remote-browser-open`: Verify it correctly encodes URLs and calls curl
2. **Unit test** for `dotfiles-local-browser-helper`: Verify HTTP handler parses query params and calls `webbrowser.open()`
3. **Integration test** (manual): SSH into remote with port forwarding, open markdown file, press `<space>o`, verify browser opens locally
4. **Regression test**: Verify local editing (non-SSH) still works normally without the SSH config

## Local Setup (One-Time)

1. Add `LocalForward 15678 localhost:15678` and `RemoteForward 15679 localhost:15679` to relevant `Host` entries in `~/.ssh/config`
2. Start the local helper in a terminal or add to local shell startup:
   ```bash
   nohup dotfiles-local-browser-helper >/dev/null 2>&1 &
   ```
3. Run `bootstrap.sh` on both local and remote machines to install scripts

## Rollout Plan

1. Add scripts to `scripts/` directory
2. Update `init.vim` with SSH conditional config
3. Update `bootstrap.sh` to symlink scripts
4. Write tests
5. Update documentation (AGENTS.md or DEVELOPMENT.md with SSH workflow notes)
6. Manual validation on an actual SSH session
