# shellcheck shell=bash
# opencode backend: a single SQLite store. Sessions link to a project by
# worktree, messages carry the model, parts carry tool calls, and a subagent
# is a child session the spawning task part points at.
# rec_sep (the record field separator) is assigned by session-outline.sh,
# which is the only thing that sources this file.
# shellcheck disable=SC2154

oc_db=${SESSION_OUTLINE_OPENCODE_DB:-$HOME/.local/share/opencode/opencode.db}

# Read-only so an opencode instance writing the same database is never disturbed.
oc_q() { sqlite3 -readonly -noheader -separator "$rec_sep" "$oc_db" "$1"; }

# Render a value as a SQL string literal. The sqlite3 CLI runs every statement a
# string contains and can read and write files through readfile()/writefile(),
# which -readonly does not prevent, so nothing reaches a query unescaped -- not
# even a worktree path, which may legitimately contain a quote.
oc_lit() { local v=${1//\'/\'\'}; printf "'%s'" "$v"; }

backend_resolve() {
  local arg=$1
  [[ -f $oc_db ]] || { echo "No opencode database at $oc_db" >&2; exit 1; }
  if [[ -n $arg ]]; then
    require_plain_id "$arg"
    oc_session=$arg
  else
    # Newest top-level session whose project worktree is this directory. Child
    # sessions are subagents, never the session the user was driving.
    oc_session=$(oc_q "SELECT s.id FROM session s JOIN project p ON p.id = s.project_id
                       WHERE p.worktree = $(oc_lit "$(pwd)") AND s.parent_id IS NULL
                       ORDER BY s.time_updated DESC, s.time_created DESC LIMIT 1;")
    [[ -n $oc_session ]] || { echo "No opencode sessions for $(pwd)" >&2; exit 1; }
  fi
}

# Distinct models a session's assistant messages ran on, in first-seen order.
oc_models() {
  oc_q "SELECT COALESCE(json_extract(data,'\$.modelID'),'') FROM message
        WHERE session_id = $(oc_lit "$1") AND json_extract(data,'\$.role') = 'assistant'
        ORDER BY time_created, id;" | awk 'NF && !seen[$0]++' | paste -sd, -
}

backend_header() {
  local title models
  echo "Session: $oc_session"
  title=$(oc_q "SELECT COALESCE(title,'') FROM session WHERE id = $(oc_lit "$oc_session");")
  [[ -n $title ]] && echo "Title:   $title"
  models=$(oc_models "$oc_session")
  [[ -n $models ]] && echo "Models:  $models"
  return 0
}

# Emit "kind<TAB>text<TAB>model<TAB>child_session" rows for one session, in
# message then part order. Whitespace is flattened in SQL so every row stays
# on one line; synthetic parts are tool replay and compaction notices, not
# anything the user typed.
oc_scan() {
  oc_q "
    WITH rows AS (
      SELECT
        json_extract(m.data,'\$.role') AS role,
        json_extract(p.data,'\$.type') AS ptype,
        COALESCE(json_extract(p.data,'\$.tool'),'') AS tool,
        COALESCE(json_extract(p.data,'\$.synthetic'),0) AS synthetic,
        trim(replace(replace(replace(COALESCE(json_extract(p.data,'\$.text'),''),
             char(10),' '), char(13),' '), char(9),' ')) AS text,
        COALESCE(json_extract(p.data,'\$.state.input.name'),'') AS skill,
        COALESCE(json_extract(p.data,'\$.state.input.subagent_type'),'') AS atype,
        trim(replace(replace(replace(COALESCE(json_extract(p.data,'\$.state.input.description'),''),
             char(10),' '), char(13),' '), char(9),' ')) AS descr,
        COALESCE(json_extract(p.data,'\$.state.metadata.model.modelID'),'') AS amodel,
        COALESCE(json_extract(p.data,'\$.state.metadata.sessionId'),'') AS child
      FROM message m JOIN part p ON p.message_id = m.id
      WHERE m.session_id = $(oc_lit "$1")
      ORDER BY m.time_created, m.id, p.time_created, p.id
    )
    SELECT CASE
             WHEN tool = 'skill' THEN 'SKILL'
             WHEN tool = 'task'  THEN 'AGENT'
             ELSE 'PROMPT' END,
           CASE
             WHEN tool = 'skill' THEN skill
             WHEN tool = 'task'  THEN '[' || atype || '] ' || descr
             WHEN length(text) > 110 THEN substr(text,1,110) || '...'
             ELSE text END,
           CASE WHEN tool = 'task' THEN amodel ELSE '' END,
           CASE WHEN tool = 'task' THEN child ELSE '' END
    FROM rows
    WHERE (tool IN ('skill','task'))
       OR (role = 'user' AND ptype = 'text' AND synthetic = 0 AND text <> '');"
}

# Walk a session, recursing into each subagent's own child session one level down.
oc_emit() {
  local depth=$1 session=$2 kind text model child
  while IFS=$rec_sep read -r kind text model child; do
    printf '%s%s%s%s%s%s%s\n' "$depth" "$rec_sep" "$kind" "$rec_sep" "$text" "$rec_sep" "$model"
    [[ -n ${child:-} ]] || continue
    # A child that points back up the tree would recurse forever.
    [[ $depth -lt 10 ]] || continue
    oc_emit "$((depth + 1))" "$child" | awk -F"$rec_sep" '$2 != "PROMPT"' || true
  done < <(oc_scan "$session")
}

backend_records() { oc_emit 0 "$oc_session"; }
