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
