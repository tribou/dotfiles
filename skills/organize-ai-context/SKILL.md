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

## 2. Interactive Phase
Engage the user to fill in gaps and confirm assumptions using the `question` tool:
- Verify the inferred tech stack.
- Ask for core architectural entry points and design patterns.
- Confirm the bug fix and testing policy (e.g., required CI commands like `just test-unit`).

## 3. Generation Phase
Draft and write the primary context files. **All primary context files MUST require the following theme statement at the top to help align the current and future content.**

| File | Theme Statement |
|---|---|
| `CLAUDE.md` | *Global rules, command reference, and index to all project context — the only file AI agents need to open first* |
| `AGENTS.md` | *Non-interactive shell safety flags — everything else lives in CLAUDE.md* |
| `docs/ARCHITECTURE.md` | *What is this system? — components, data flow, DB schema, external APIs, and directory layout* |
| `docs/DEVELOPMENT.md` | *How do we write code here? — naming conventions, design principles, error handling, reliability strategy, and planned stack* |
| `docs/PRODUCT.md` | *What are we building and why? — user story, requirements, success criteria, and business domain context helpful for understanding **why** features are built the way they are* |
| `docs/SECURITY.md` | *How do we keep secrets safe? — environment variables, API key policy, and auth posture* |
| `docs/TESTING.md` | *How do we test and fix bugs? — testing requirements, test running instructions, and bug fix policies.* |

### Enforcing CRITICAL Rules in CLAUDE.md
When generating `CLAUDE.md`, you MUST enforce limiting and curating proper global rules under a "CRITICAL Rules" heading. You must suggest the following best practice rules for every repo:
1. **Git commits**: single-line only with `git commit -m "..."`, no Co-Authored-By
2. **Bash syntax checking**: use `bashcheck` — never `bash -n`
3. **After making any changes, run tests**: [concisely instruct how to run tests in the repo]
4. **Bug fixes require TDD tests**: see `docs/TESTING.md` for policy
5. **Creating new skills**: use `superpowers:writing-skills` skill

You MUST also prompt the user to review and suggest additional global rules when appropriate.
