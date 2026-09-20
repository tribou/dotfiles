---
name: session-outline
description: Use when the user asks which agents or subagents ran, which skills or slash commands were used, which models did the work, or for an outline, summary, or audit of tool activity in a current or past Claude Code or opencode session.
---

# Session Outline

## Overview

Claude Code and opencode both record every session. `session-outline.sh` (in this skill's directory) reads either one and prints each user prompt in order, with the skills and agents that ran for it nested underneath, plus the model each ran on.

The two runtimes store sessions completely differently, so the script has one backend per runtime behind a shared renderer. It picks the backend for you.

## Usage

Run from the project directory the session belongs to:

```bash
~/.claude/skills/session-outline/session-outline.sh                     # most recent session here, either runtime
~/.claude/skills/session-outline/session-outline.sh <session-id>         # a specific session
~/.claude/skills/session-outline/session-outline.sh <path.jsonl>         # a Claude Code transcript file
~/.claude/skills/session-outline/session-outline.sh --runtime opencode   # most recent opencode session here
```

Runtime is auto-detected: an `ses_`-prefixed id is opencode, a file path or UUID is Claude Code, and with no argument the runtime with the more recent session for this directory wins. `--runtime claude-code|opencode` forces the choice. The `Runtime:` header always states which backend ran.

To find past sessions:
- **Claude Code**: `ls -t ~/.claude/projects/<project-dir>/*.jsonl`, where `<project-dir>` is the absolute path with `/` and `.` replaced by `-`. The user can also browse with `/resume`.
- **opencode**: `sqlite3 -readonly ~/.local/share/opencode/opencode.db "SELECT s.id, s.title FROM session s JOIN project p ON p.id=s.project_id WHERE p.worktree='$(pwd)' AND s.parent_id IS NULL ORDER BY s.time_updated DESC LIMIT 20;"`

Output lines:

| Prefix | Meaning |
|---|---|
| `CMD` | Slash command the user typed (Claude Code only) |
| `PROMPT` | User prompt, truncated |
| `SKILL` | Skill loaded via the skill tool |
| `AGENT [type]` | Subagent launched, with its description and the model it ran on in parentheses; deeper-indented lines are that agent's own skills and agents |

The `Models:` header lists the models the main session's own turns ran on, in first-seen order — more than one means the model changed mid-session.

Show the output to the user as-is in a code block. Add a short summary only if they asked for one.

## Architecture

```
session-outline.sh      entry: parses args, picks runtime, renders
lib/detect.sh           which runtime has the newer session for this directory
lib/claude-code.sh      JSONL transcripts  -> records
lib/opencode.sh         opencode.db SQLite -> records
```

Backends share one contract. Each defines `backend_resolve <arg>`, `backend_header`, and `backend_records`, where `backend_records` emits tab-separated `depth`, `kind`, `text`, `model` and the entry script owns all formatting. To add a third runtime, add `lib/<name>.sh` implementing those three functions — no change to the renderer.

Where each field comes from:

| Record | Claude Code | opencode |
|---|---|---|
| Session store | `~/.claude/projects/<slug>/<id>.jsonl` | `~/.local/share/opencode/opencode.db` |
| Locate by directory | path slug in the directory name | `project.worktree` → `session.project_id` |
| Session model | `.message.model` on assistant records | `message.data.modelID` |
| `SKILL` | `tool_use` where `name == "Skill"` → `.input.skill` | `part.data.tool == "skill"` → `state.input.name` |
| `AGENT` | `tool_use` where `name == "Agent"` → `.input.subagent_type` | `part.data.tool == "task"` → `state.input.subagent_type` |
| Agent's transcript | `subagents/*.meta.json` matched on `toolUseId` | `state.metadata.sessionId` → child `session.id` |
| Agent's model | its transcript, else meta alias, else requested | `state.metadata.model.modelID` on the task part |

opencode is read with `sqlite3 -readonly` so a running opencode instance is never disturbed.

## Limits

- Skills injected by hooks (a SessionStart hook pasting skill text) are not tool calls and do not appear.
- Agents still running have incomplete transcripts, so their nested activity and resolved model may be missing.
- The `Models:` header covers the whole session, not individual turns.
- **opencode**: slash commands expand into ordinary user text before being stored, so they show as `PROMPT`, not `CMD`.
- **opencode**: a skill whose body is injected as a user message (rather than called through the `skill` tool) appears as a `PROMPT` containing that skill's markdown. Only `skill` tool calls become `SKILL` lines.
- **opencode**: the legacy JSON store under `~/.local/share/opencode/storage/` is not read. opencode migrated to SQLite; that tree is stale leftovers.
- Sessions from another project directory need an explicit session id or path.
