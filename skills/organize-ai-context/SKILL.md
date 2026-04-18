---
name: organize-ai-context
description: Use when setting up a new repository, when AI agents lack project context, or when codebase guidelines are scattered and unstructured.
---

# Organize AI Context

## Overview
Use this skill to help any repo organize its AI agent context into standard files: `CLAUDE.md`, `AGENTS.md`, and `docs/` files (like `ARCHITECTURE.md`, `TESTING.md`, and `DEVELOPMENT.md`).

This skill can be used to either setup a new repository or groom an existing one to realign its project context. Run this periodically to continually align and improve the context—much like weeding a garden.

## Mandatory Step: Task Management
Before proceeding, you MUST check if the repository uses BEADS by calling `bd prime`.
- If it does, you MUST use `bd` to manage tasks.
- Otherwise, you MUST use the `todowrite` tool to create a checklist for the following phases before taking action.

## 1. Scan Phase
Autonomously scan the repository:
- **Tech Stack**: Use `read`, `glob`, `bash` to analyze root config files (e.g., `package.json`, `Cargo.toml`, `requirements.txt`).
- **Testing**: Look for test directories (`tests/`, `__tests__/`, `spec/`) to infer the testing framework.
- **Conventions**: Check any existing `README.md` or `docs/` for current guidelines.
