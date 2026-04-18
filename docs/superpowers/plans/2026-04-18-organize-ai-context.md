# Organize AI Context Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `organize-ai-context` skill to autonomously scan, interactively refine, and generate standard AI context files (`CLAUDE.md`, `AGENTS.md`, and `docs/`) for any repository.

**Architecture:** A single markdown skill file `skills/organize-ai-context/SKILL.md` enforcing a Scan -> Interactive -> Generate workflow, with strict rules for document splitting and BEADS task management.

**Tech Stack:** AI Agent Skill (Markdown with YAML frontmatter).

---

### Task 1: Base Skill Structure and Frontmatter

**Files:**
- Create: `skills/organize-ai-context/SKILL.md`

- [ ] **Step 1: Verify Directory Exists**

```bash
mkdir -p skills/organize-ai-context
```

- [ ] **Step 2: Write Frontmatter and Overview**

```bash
cat << 'EOF' > skills/organize-ai-context/SKILL.md
---
name: organize-ai-context
description: Use when setting up a new repository, when AI agents lack project context, or when codebase guidelines are scattered and unstructured.
---

# Organize AI Context

## Overview
Use this skill to help any repo organize its AI agent context into standard files: `CLAUDE.md`, `AGENTS.md`, and `docs/` files (like `ARCHITECTURE.md`, `TESTING.md`, and `DEVELOPMENT.md`).

This skill can be used to either setup a new repository or groom an existing one to realign its project context. Run this periodically to continually align and improve the context—much like weeding a garden.
EOF
```

- [ ] **Step 3: Commit Base Structure**

```bash
git add skills/organize-ai-context/SKILL.md
git commit -m "feat: setup organize-ai-context skill with frontmatter"
```

### Task 2: Mandatory BEADS and Scan Phase

**Files:**
- Modify: `skills/organize-ai-context/SKILL.md`

- [ ] **Step 1: Append BEADS rules and Scan Phase**

```bash
cat << 'EOF' >> skills/organize-ai-context/SKILL.md

## Mandatory Step: Task Management
Before proceeding, you MUST check if the repository uses BEADS by calling `bd prime`.
- If it does, you MUST use `bd` to manage tasks.
- Otherwise, you MUST use the `todowrite` tool to create a checklist for the following phases before taking action.

## 1. Scan Phase
Autonomously scan the repository:
- **Tech Stack**: Use `read`, `glob`, `bash` to analyze root config files (e.g., `package.json`, `Cargo.toml`, `requirements.txt`).
- **Testing**: Look for test directories (`tests/`, `__tests__/`, `spec/`) to infer the testing framework.
- **Conventions**: Check any existing `README.md` or `docs/` for current guidelines.
EOF
```

- [ ] **Step 2: Commit BEADS and Scan Phase**

```bash
git add skills/organize-ai-context/SKILL.md
git commit -m "feat: add mandatory BEADS check and Scan phase to organize-ai-context"
```

### Task 3: Interactive Phase

**Files:**
- Modify: `skills/organize-ai-context/SKILL.md`

- [ ] **Step 1: Append Interactive Phase**

```bash
cat << 'EOF' >> skills/organize-ai-context/SKILL.md

## 2. Interactive Phase
Engage the user to fill in gaps and confirm assumptions using the `question` tool:
- Verify the inferred tech stack.
- Ask for core architectural entry points and design patterns.
- Confirm the bug fix and testing policy (e.g., required CI commands like `just test-unit`).
EOF
```

- [ ] **Step 2: Commit Interactive Phase**

```bash
git add skills/organize-ai-context/SKILL.md
git commit -m "feat: add Interactive phase to organize-ai-context"
```

### Task 4: Generation Phase and Theme Statements

**Files:**
- Modify: `skills/organize-ai-context/SKILL.md`

- [ ] **Step 1: Append Generation Phase**

```bash
cat << 'EOF' >> skills/organize-ai-context/SKILL.md

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
EOF
```

- [ ] **Step 2: Commit Generation Phase**

```bash
git add skills/organize-ai-context/SKILL.md
git commit -m "feat: add Generation phase, CRITICAL Rules, and theme statements"
```

### Task 5: Red Flags and Anti-Rationalization

**Files:**
- Modify: `skills/organize-ai-context/SKILL.md`

- [ ] **Step 1: Append Red Flags and Error Handling**

```bash
cat << 'EOF' >> skills/organize-ai-context/SKILL.md

## Red Flags & Bulletproofing Against Rationalizations
You MUST explicitly forbid common shortcuts:
- *"It's faster to write a single `CLAUDE.md`."* -> **Counter**: Do NOT combine architecture, testing, or development into the root `CLAUDE.md`. You MUST split them into the `docs/` directory.
- *"The repo is too simple for multiple files."* -> **Counter**: Even simple repos require the standard split to maintain consistency across projects.

## Error Handling
If the repository structure is highly non-standard or overly large to scan efficiently, lean more heavily on the interactive questionnaire to gather context rather than attempting error-prone guesses.
EOF
```

- [ ] **Step 2: Commit Red Flags**

```bash
git add skills/organize-ai-context/SKILL.md
git commit -m "feat: add Red Flags and anti-rationalization guidelines"
```