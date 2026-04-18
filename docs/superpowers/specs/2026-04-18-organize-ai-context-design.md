# Organize AI Context Skill Design

## Overview
A skill to help any repo organize its AI agent context into standard files: `CLAUDE.md`, `AGENTS.md`, and `docs/` files (like architecture, testing, and patterns).

## Architecture
- A new skill file located at `skills/organize-ai-context/SKILL.md`.

## Process Flow

### 1. Scan Phase
The agent autonomously scans the repository:
- **Tech Stack**: Uses `read`, `glob`, `bash` to analyze root config files (e.g., `package.json`, `Cargo.toml`, `requirements.txt`).
- **Testing**: Looks for test directories (`tests/`, `__tests__/`, `spec/`) to infer the testing framework.
- **Conventions**: Checks any existing `README.md` or `docs/` for current guidelines.

### 2. Interactive Phase
The agent engages the user to fill in gaps and confirm assumptions using the `question` tool.
- Verifies the inferred tech stack.
- Asks for core architectural entry points and design patterns.
- Confirms the bug fix and testing policy (e.g., required CI commands like `just test-unit`).

### 3. Generation Phase
The agent drafts and writes the context files:
- **`CLAUDE.md`**: Global rules, default tech stack, and a Context Index pointing to the docs directory.
- **`AGENTS.md`**: Defines agent responsibilities, subagent routing, and general workflow rules.
- **`docs/architecture.md`**: High-level system design and key code locations.
- **`docs/patterns.md`**: Code style, established conventions, and typical developer workflows.
- **`docs/testing.md`**: Testing requirements, test running instructions, and bug fix policies.

## Error Handling
- If the repository structure is highly non-standard or overly large to scan efficiently, the skill will lean more heavily on the interactive questionnaire to gather context rather than attempting error-prone guesses.

## Testing Strategy
- Manual verification: Run the skill on this dotfiles repository itself or an empty sample repo to ensure it accurately drafts and splits the files correctly.
