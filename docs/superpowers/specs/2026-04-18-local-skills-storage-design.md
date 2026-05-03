# Local Skills Storage Design

## Overview

Store custom AI skills (Claude Code + opencode) in the dotfiles repo so they are available on every machine where dotfiles are installed.

## Problem

Custom skills written for Claude Code and opencode are not currently versioned or portable. They need to be available wherever dotfiles are installed without manual setup.

## Solution

Add a `skills/` directory to the dotfiles repo and symlink it to `~/.claude/skills/` via `bootstrap.sh`. Both Claude Code and opencode read from `~/.claude/skills/`, so one symlink covers both tools.

## Directory Structure

```
dotfiles/
  skills/
    <skill-name>/
      SKILL.md
```

Each skill follows the standard `SKILL.md` format with YAML frontmatter (`name`, `description`) and markdown content.

## Bootstrap Integration

One addition to `bootstrap.sh` alongside existing symlinks:

```bash
# AI skills (Claude Code + opencode)
linkFileToHome "skills" ".claude/skills"
```

This creates `~/.claude/skills → ~/dev/dotfiles/skills/`.

## CLAUDE.md Changes

1. Add rule: "When creating a new skill, use `superpowers:writing-skills`"
2. Add context index entry: "Custom AI skills (Claude Code + opencode) → `skills/`"

## Workflow

- New skill: create `skills/<name>/SKILL.md`, commit, push
- New machine: `./bootstrap.sh` creates the symlink; all skills available immediately
- Updates: `git pull` on any machine picks up new/updated skills

## Compatibility

- Claude Code reads `~/.claude/skills/` (personal skills)
- OpenCode reads `~/.claude/skills/` (one of its global lookup paths)
- No per-tool divergence expected; if needed, a second symlink can be added later
