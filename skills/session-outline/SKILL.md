---
name: session-outline
description: Use when the user asks which agents or subagents ran, which skills or slash commands were used, or for an outline, summary, or audit of tool activity in the current or a past Claude Code session.
---

# Session Outline

## Overview

Claude Code saves every session as a transcript. `session-outline.sh` (in this skill's directory) reads it and prints each user prompt in order, with the skills and agents that ran for it nested underneath. Each agent also gets its own skills and agents listed.

## Usage

Run from the project directory the session belongs to:

```bash
~/.claude/skills/session-outline/session-outline.sh                # most recent session (the current one)
~/.claude/skills/session-outline/session-outline.sh <session-id>   # a specific session
~/.claude/skills/session-outline/session-outline.sh <path.jsonl>   # any transcript file
```

To find past session IDs: `ls -t ~/.claude/projects/<project-dir>/*.jsonl`, where `<project-dir>` is the absolute path with `/` and `.` replaced by `-`. The user can also browse them with `/resume`.

Output lines:

| Prefix | Meaning |
|---|---|
| `CMD` | Slash command the user typed (including skill commands such as `/brainstorming`) |
| `PROMPT` | User prompt, truncated |
| `SKILL` | Skill Claude loaded via the Skill tool |
| `AGENT [type]` | Subagent launched, with its description; deeper-indented lines are that agent's own skills and agents |

Show the output to the user as-is in a code block. Add a short summary only if they asked for one.

## Limits

- Skills injected by hooks (for example a SessionStart hook pasting skill text) are not Skill tool calls and do not appear.
- Agents still running have incomplete transcripts, so their nested activity may be missing.
- Transcripts live under `~/.claude/projects/`; sessions from another project directory need the explicit path.
