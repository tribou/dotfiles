#!/usr/bin/env bash
# Print the runtime with the most recent session for the current directory.
# Claude Code wins ties, since its transcript is the one this tool grew up on.
set -euo pipefail

cc_root=${SESSION_OUTLINE_CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}
cc_proj=$cc_root/$(pwd | sed 's#[^A-Za-z0-9]#-#g')
oc_db=${SESSION_OUTLINE_OPENCODE_DB:-$HOME/.local/share/opencode/opencode.db}

cc_time=0
for f in "$cc_proj"/*.jsonl; do
  [[ -f $f ]] || continue
  t=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
  [[ $t -gt $cc_time ]] && cc_time=$t
done

oc_time=0
if [[ -f $oc_db ]] && command -v sqlite3 >/dev/null 2>&1; then
  # Double any quote in the worktree: the sqlite3 CLI runs whatever statements
  # the string contains, and -readonly does not stop readfile()/writefile().
  worktree=$(pwd); worktree=${worktree//\'/\'\'}
  oc_time=$(sqlite3 -readonly -noheader "$oc_db" \
    "SELECT COALESCE(MAX(s.time_updated)/1000,0) FROM session s JOIN project p ON p.id = s.project_id
     WHERE p.worktree = '$worktree' AND s.parent_id IS NULL;" 2>/dev/null || echo 0)
  # A sqlite error or an unexpected row count must not reach an arithmetic test.
  [[ $oc_time =~ ^[0-9]+$ ]] || oc_time=0
fi

if [[ $oc_time -gt $cc_time ]]; then echo opencode; else echo claude-code; fi
