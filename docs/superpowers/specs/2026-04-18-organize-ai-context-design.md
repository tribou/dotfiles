# Organize AI Context Skill Design

## Overview
A skill to help any repo organize its AI agent context into standard files: `CLAUDE.md`, `AGENTS.md`, and `docs/` files (like architecture, testing, and patterns).

## Architecture
- A new skill file located at `skills/organize-ai-context/SKILL.md`.

## YAML Frontmatter (Claude Search Optimization)
- **name**: `organize-ai-context`
- **description**: Use when setting up a new repository, when AI agents lack project context, or when codebase guidelines are scattered and unstructured. *(Note: Must not summarize workflow)*

## Process Flow

**Mandatory Step**: The skill MUST instruct the agent to use the `todowrite` tool to create a checklist for the following phases before taking action.

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

## Red Flags & Bulletproofing Against Rationalizations
The skill must explicitly forbid common shortcuts.
- *"It's faster to write a single `CLAUDE.md`."* -> **Counter**: Do NOT combine architecture, testing, or patterns into the root `CLAUDE.md`. You MUST split them into the `docs/` directory.
- *"The repo is too simple for multiple files."* -> **Counter**: Even simple repos require the standard split to maintain consistency across projects.

## Error Handling
- If the repository structure is highly non-standard or overly large to scan efficiently, the skill will lean more heavily on the interactive questionnaire to gather context rather than attempting error-prone guesses.

## Testing Strategy (TDD for Skills)
We must follow the strict RED-GREEN-REFACTOR cycle for skill authoring:
1. **RED (Baseline)**: Run a pressure scenario asking a subagent to "organize the AI context for this repo" WITHOUT the skill. Document its exact failures and rationalizations (e.g., dumping everything into `CLAUDE.md`, failing to ask questions).
2. **GREEN**: Write the minimal skill to address those specific baseline failures, then run the scenario WITH the skill to verify the agent complies with the strict split and interactive phases.
3. **REFACTOR**: Identify any new rationalizations the agent makes during testing and plug the loopholes in the skill documentation.