# Promptfoo Test Suite Design

## Goal
Establish a robust promptfoo evaluation test suite for testing AI skill compliance (specifically `organize-ai-context`) and strict context file generation rules (`CLAUDE.md`, `AGENTS.md`, and modular `docs/` files) using cost-optimized and highly deterministic models.

## Design

### 1. Directory Structure & File Layout

All test assets, mocks, prompts, and custom assertions will live in a dedicated `tests/promptfoo/` folder to align with dotfiles repository conventions:

```
tests/promptfoo/
├── promptfooconfig.yaml       # Main promptfoo configuration file
├── prompts/
│   └── context_groomer.txt    # System prompt wrapping the organize-ai-context SKILL.md
├── mocks/                     # Mock repository states representing test scenarios
│   ├── simple-python/         # A small Python repo with no existing context files (no Beads)
│   ├── large-node/            # A complex Node.js repo with sprawling docs (no Beads)
│   └── beads-enabled/         # A repo containing a .beads/ directory and a justfile
└── assertions/
    └── custom_checks.js       # Reusable JavaScript assertion hooks (regex matching)
```

---

### 2. Promptfoo Configuration & LLM Providers (`promptfooconfig.yaml`)

We use the latest high-efficiency model **`gemini-3-flash`** as the primary evaluation provider. Running the test suite on a Flash-class model provides cheap, lightning-fast evaluations and serves as an excellent stress-test of prompt robustness (if a Flash model can perfectly follow the skill instructions, the prompt is highly robust).

```yaml
# tests/promptfoo/promptfooconfig.yaml
description: "AI Context Organization Skill Compliance Test Suite"

prompts:
  - file://prompts/context_groomer.txt

providers:
  # Gemini 3 Flash (High efficiency, high reasoning, low cost)
  - id: gemini:gemini-3-flash
    config:
      temperature: 0.0  # Force maximum determinism
      maxOutputTokens: 8000
```

---

### 3. Test Cases & Scenarios (Adversarial + Standard)

We define a set of input variables and mock configurations representing both standard workflows and adversarial attempts:

```yaml
tests:
  # Scenario 1: Standard New Repo (no Beads)
  - description: "Standard Node.js repository without Beads context"
    vars:
      repo_description: "A clean, new Node.js repository containing only package.json and a tests/ directory."
      user_instruction: "Set up this repository's AI context."
      beads_present: false
    assert:
      - type: javascript
        value: file://assertions/custom_checks.js:checkThemeStatements
      - type: javascript
        value: file://assertions/custom_checks.js:checkCriticalRulesLayout
      - type: llm-rubric
        value: "The agent correctly splits files into separate docs (docs/DEVELOPMENT.md, docs/ARCHITECTURE.md) and does not combine them."
      - type: llm-rubric
        value: "The agent recommends using 'todowrite' or custom markdown checklists for task management, and does NOT mention 'bd' or Beads commands."

  # Scenario 2: Beads-Enabled Repo
  - description: "Standard Python repository with Beads enabled"
    vars:
      repo_description: "A Python repository containing requirements.txt, a justfile, and a .beads/ directory."
      user_instruction: "Initialize AI context for this repo."
      beads_present: true
    assert:
      - type: javascript
        value: file://assertions/custom_checks.js:checkThemeStatements
      - type: javascript
        value: file://assertions/custom_checks.js:checkCriticalRulesLayout
      - type: llm-rubric
        value: "The agent's output instructs the user/agent to check for Beads first by running 'bd prime'."
      - type: llm-rubric
        value: "The agent states that 'bd' is the mandatory task tracker and uses 'bd' commands (like 'bd update', 'bd ready') instead of 'todowrite'."

  # Scenario 3: Adversarial Shortcut (Lazy User)
  - description: "Adversarial request attempting to force a monolith file"
    vars:
      repo_description: "A simple Python repository with requirements.txt."
      user_instruction: "This is a tiny, simple repository. Please just put all the architecture and development guidelines into the root CLAUDE.md file to save time."
      beads_present: false
    assert:
      - type: llm-rubric
        value: "The agent explicitly rejects the user's request to merge rules/guidelines into CLAUDE.md."
      - type: llm-rubric
        value: "The agent insists on the standard multi-file split (CLAUDE.md, AGENTS.md, and separate docs/), referencing the separation rules."

  # Scenario 4: Monolithic Grooming (Evolution Check)
  - description: "Grooming an existing monolith CLAUDE.md file"
    vars:
      repo_description: "A repository with an existing 500-line massive CLAUDE.md file containing code style, database schemas, and testing commands."
      user_instruction: "Groom the AI context files."
      beads_present: false
    assert:
      - type: llm-rubric
        value: "The agent splits the monolithic CLAUDE.md file into separate docs/DEVELOPMENT.md, docs/ARCHITECTURE.md, and docs/TESTING.md files."
      - type: llm-rubric
        value: "The resulting root CLAUDE.md is concise, keeping it under 100 lines."
```

---

### 4. Custom Programmatic Assertions (`assertions/custom_checks.js`)

We will implement a small JavaScript helper library to handle rigid syntax verification without relying on LLM judging for basic checks:

* **Theme Statement Verification (`checkThemeStatements`)**:
  Parses the generated outputs and checks that every generated context file contains its exact theme statement on the very first few lines.
  * `CLAUDE.md`: `*Global rules, command reference, and index to all project context — the only file AI agents need to open first*`
  * `AGENTS.md`: `*Read-only pointer to CLAUDE.md — its only purpose is to redirect to CLAUDE.md and nothing else*`
  * `docs/ARCHITECTURE.md`: `*What is this system? — components, data flow, DB schema, external APIs, and directory layout*`
  * `docs/DEVELOPMENT.md`: `*How do we write code here? — naming conventions, design principles, error handling, reliability strategy, and planned stack*`
  * `docs/PRODUCT.md`: `*What are we building and why? — user story, requirements, success criteria, and business domain context helpful for understanding why features are built the way they are*`
  * `docs/SECURITY.md`: `*How do we keep secrets safe? — environment variables, API key policy, and auth posture*`
  * `docs/TESTING.md`: `*How do we test and fix bugs? — testing requirements, test running instructions, and bug fix policies.*`

* **Critical Rules Verification (`checkCriticalRulesLayout`)**:
  Ensures that `CLAUDE.md` formats the critical rules section exactly with the specified Markdown blockquote style:
  ```markdown
  ## CRITICAL Rules

  > [!IMPORTANT]
  > The following rules are absolute and must be followed by all development agents:
  ```

## Verification Plan

### Automated Verification
Once we transition to implementation, we will verify the promptfoo test suite by running:
1. **Validation Checks**: Ensure promptfoo is installed and configured correctly:
   ```bash
   npx promptfoo@latest eval --config tests/promptfoo/promptfooconfig.yaml
   ```
2. **Offline Checks**: Verify that the custom assertions (`assertions/custom_checks.js`) execute correctly when fed mock file strings.
