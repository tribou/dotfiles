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
Draft and write the primary context files. **All primary context files MUST require the following theme statement at the top to help align the current and future content.** (Note: You may properly combine similar context files into a single file within `docs/` if appropriate, merging their theme statements).

| File | Theme Statement |
|---|---|
| `CLAUDE.md` | *Global rules, command reference, and index to all project context — the only file AI agents need to open first* |
| `AGENTS.md` | *Read-only pointer to CLAUDE.md — its only purpose is to redirect to CLAUDE.md and nothing else* |
| `docs/ARCHITECTURE.md` | *What is this system? — components, data flow, DB schema, external APIs, and directory layout* |
| `docs/DEVELOPMENT.md` | *How do we write code here? — naming conventions, design principles, error handling, reliability strategy, and planned stack* |
| `docs/PRODUCT.md` | *What are we building and why? — user story, requirements, success criteria, and business domain context helpful for understanding **why** features are built the way they are* |
| `docs/SECURITY.md` | *How do we keep secrets safe? — environment variables, API key policy, and auth posture* |
| `docs/TESTING.md` | *How do we test and fix bugs? — testing requirements, test running instructions, and bug fix policies.* |

### Enforcing CRITICAL Rules in CLAUDE.md
When generating `CLAUDE.md`, you MUST enforce limiting and curating proper global rules under a SINGLE "CRITICAL Rules" heading. 
**DO NOT create an additional Rules section of any kind.**
- If a rule is truly global, it goes in "CRITICAL Rules".
- If a rule is not global, it MUST go in the appropriate `docs/*` file (e.g., `docs/DEVELOPMENT.md`).

You must suggest the following best practice rules for the "CRITICAL Rules" section in every repo:
1. **Git commits**: single-line only with `git commit -m "..."`, no Co-Authored-By
2. **Bash syntax checking**: use `bashcheck` — never `bash -n`
3. **After making any changes, run tests**: [concisely instruct how to run tests in the repo]
4. **Bug fixes require TDD tests**: see `docs/TESTING.md` for policy
5. **Creating new skills**: use `superpowers:writing-skills` skill

You MUST also prompt the user to review and suggest additional global rules when appropriate.

## Red Flags & Bulletproofing Against Rationalizations
You MUST explicitly forbid common shortcuts:
- *"It's faster to write a single `CLAUDE.md`."* -> **Counter**: Do NOT combine architecture, testing, or development into the root `CLAUDE.md`. You MUST place them in the `docs/` directory. You may properly combine similar context files within `docs/` when appropriate (e.g., if the repo is very small or the topics overlap significantly).
- *"The repo is too simple for multiple files."* -> **Counter**: While you may combine similar context files within `docs/`, you must still keep them out of the root `CLAUDE.md` to maintain a clean project root.

## Error Handling
If the repository structure is highly non-standard or overly large to scan efficiently, lean more heavily on the interactive questionnaire to gather context rather than attempting error-prone guesses.
