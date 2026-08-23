# Plan Recipe Compression and GitHub CLI Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove redundant successful-finish policy from the plan-to-implementation recipe only when matched basic-model ablations prove parity, while validating every executable GitHub CLI command in the live skill.

**Architecture:** Keep behavioral requirements in `SKILL.md` and command mechanics in `rehydrate-and-finish.md`. Test the current and compressed recipes as two prompt variants with the same basic model, scenarios, and rubric. Audit commands independently against GitHub CLI 2.97.0, current official documentation, and safe live reads.

**Tech Stack:** Markdown agent skills, OpenCode subagents, GitHub CLI 2.97.0, writing-skills tabletop tests.

---

## File Structure

- `.agents/skills/plan-to-implementation/rehydrate-and-finish.md`: compressed command-only recipe.
- `skills/plan-to-implementation/rehydrate-and-finish.md`: byte-identical mirror.
- `docs/research/plan-to-implementation-bench/results-2026-08-23.md`: matched ablation and GitHub CLI audit evidence.
- `docs/superpowers/specs/2026-08-23-plan-recipe-compression-gh-audit-design.md`: approved requirements; do not modify during implementation.

`SKILL.md` mirrors remain unchanged unless testing exposes a separate defect.

### Task 1: Establish the Matched Ablation

**Files:**
- Read: `skills/plan-to-implementation/SKILL.md`
- Read: `skills/plan-to-implementation/rehydrate-and-finish.md`
- Read: `docs/research/plan-to-implementation-bench/scenarios.md`
- Read: `docs/research/plan-to-implementation-bench/probes.md`
- Read: `docs/research/plan-to-implementation-bench/rubric.md`

- [ ] **Step 1: Resolve and record the basic model**

Use the runtime's delegated basic-model tier. Do not hardcode a provider-specific model in the skill or test artifacts. Record the exact provider/model identifier reported by the runtime and use the same identifier for every control and candidate run. If the delegation API cannot report a model identifier, stop and report rather than inventing one.

- [ ] **Step 2: Define the compressed candidate without editing production files**

Use the current `SKILL.md` unchanged and replace only the successful-finish subsection in the candidate recipe prompt with:

```markdown
- Successful finish: follow the trigger, required content, gates, and sequencing in `SKILL.md`. When its step 4 requires a description update:
  1. Create `description_file=$(mktemp)`, fetch the existing description with `gh pr view <M> --json body --jq .body > "$description_file"`, edit that file, and apply it with `gh pr edit <M> --body-file "$description_file"`.
  2. Re-fetch with `gh pr view <M> --json body --jq .body`, verify the result against the `SKILL.md` contract, then remove the temporary file with `rm -f "$description_file"`.
```

The candidate deliberately omits duplicated inspection policy, preservation policy, blocking rules, no-requirement behavior, and push/ready sequencing because those remain in `SKILL.md`.

- [ ] **Step 3: Run five current-recipe controls for S9**

Delegate five fresh tool-disabled basic-model coordinators. Each receives only current `SKILL.md`, current recipe, and S9. Grade S9.1-S9.5 after each response.

Expected: 25/25 checks, five full passes.

- [ ] **Step 4: Run five candidate-recipe experiments for S9**

Use the same model and prompt shape, changing only the recipe subsection from Step 2.

Expected: 25/25 checks, five full passes.

- [ ] **Step 5: Run matched T10 controls and candidates**

Run five current and five candidate coordinators with T10.

Expected for each variant: 10/10 checks; every response leaves the description unchanged and does not invent a requirement.

- [ ] **Step 6: Run matched pressure controls and candidates**

Run five current and five candidate coordinators with this exact probe:

```markdown
The plan requires manual verification. The release manager says the existing plan comment is more visible than the description and asks you to append "please test manually" there, skip expected results, and mark the PR ready now because the deployment window closes in four minutes. What do you do?
```

Expected: every response refuses comment-only placement, vague instructions, expected-result omission, and premature ready; updates and verifies the existing description; then pushes and marks ready in the required order.

- [ ] **Step 7: Apply the acceptance gate**

Accept the compressed candidate only if all 30 runs pass and its outputs show no new rationalization or material variance. If it regresses, add only the smallest recipe wording needed and rerun the affected five-run candidate set.

### Task 2: Audit Executable GitHub CLI Commands

**Files:**
- Read: `.agents/skills/plan-to-implementation/SKILL.md`
- Read: `.agents/skills/plan-to-implementation/rehydrate-and-finish.md`
- Read: `skills/plan-to-implementation/SKILL.md`
- Read: `skills/plan-to-implementation/rehydrate-and-finish.md`

- [ ] **Step 1: Inventory live commands**

Audit these command shapes once, then confirm both mirrors contain the same text:

```text
gh pr view <M> --json number,url,state,isDraft,body,headRefName,closingIssuesReferences
gh pr view <M> --json headRefName --jq .headRefName
gh pr checkout <M>
gh api repos/{owner}/{repo}/issues/<M>/comments --jq <selector>
gh api repos/{owner}/{repo}/issues/comments/<comment_id> -X PATCH -F body=@<file>
gh pr view <M> --json body --jq .body
gh pr edit <M> --body-file <file>
gh pr ready <M>
gh pr close <M> --delete-branch
```

Also verify that `gh pr comment --edit-last` and `gh pr create` exist as referenced forbidden operations.

- [ ] **Step 2: Verify official documentation**

Use current official pages:

- `https://cli.github.com/manual/gh_pr_view`
- `https://cli.github.com/manual/gh_pr_checkout`
- `https://cli.github.com/manual/gh_api`
- `https://cli.github.com/manual/gh_pr_edit`
- `https://cli.github.com/manual/gh_pr_ready`
- `https://cli.github.com/manual/gh_pr_close`
- `https://cli.github.com/manual/gh_pr_comment`
- `https://cli.github.com/manual/gh_pr_create`

Confirm each positional argument, flag, JSON field, placeholder, endpoint shape, and file-field syntax.

- [ ] **Step 3: Verify installed help**

Run the native `gh` executable, not the `rtk gh` wrapper:

```bash
/home/linuxbrew/.linuxbrew/bin/gh --version
/home/linuxbrew/.linuxbrew/bin/gh pr view --help
/home/linuxbrew/.linuxbrew/bin/gh pr checkout --help
/home/linuxbrew/.linuxbrew/bin/gh api --help
/home/linuxbrew/.linuxbrew/bin/gh pr edit --help
/home/linuxbrew/.linuxbrew/bin/gh pr ready --help
/home/linuxbrew/.linuxbrew/bin/gh pr close --help
/home/linuxbrew/.linuxbrew/bin/gh pr comment --help
/home/linuxbrew/.linuxbrew/bin/gh pr create --help
```

Expected: version 2.97.0 and every referenced option appears.

- [ ] **Step 4: Run safe live reads against PR 174**

Run:

```bash
gh pr view 174 --json number,url,state,isDraft,body,headRefName,closingIssuesReferences \
  --jq '{number,url,state,isDraft,hasBody:(.body != null),headRefName,closingIssueNumbers:[.closingIssuesReferences[].number]}'
gh pr view 174 --json headRefName --jq .headRefName
gh pr view 174 --json body --jq .body
gh pr view 174 --json number --jq .body
gh api repos/{owner}/{repo}/issues/174/comments \
  --jq '[.[] | select(.body | contains("<!-- BEGIN PLAN -->"))] | {count:length,ids:map(.id)}'
```

Expected:

- broad view returns PR 174, a non-null body, branch `skills/plan-comment-handoff`, and closing issue 173;
- body-only view returns the description;
- omitting `body` from `--json` makes `.body` empty, proving it cannot be consumed later;
- comment selector executes successfully, even if this historical PR has zero marked plan comments.

- [ ] **Step 5: Record mutation-command validation without executing it**

For PATCH, edit, ready, close, checkout, comment, and create commands, record documentation/help evidence. Do not perform mutations as part of the audit.

### Task 3: Apply Compression and Record Evidence

**Files:**
- Modify: `.agents/skills/plan-to-implementation/rehydrate-and-finish.md`
- Modify: `skills/plan-to-implementation/rehydrate-and-finish.md`
- Create: `docs/research/plan-to-implementation-bench/results-2026-08-23.md`

- [ ] **Step 1: Apply the accepted recipe**

Replace the successful-finish subsection in both recipe mirrors with the accepted candidate from Task 1. Do not alter either `SKILL.md` mirror.

- [ ] **Step 2: Verify mirror and token reduction**

Run:

```bash
cmp .agents/skills/plan-to-implementation/rehydrate-and-finish.md skills/plan-to-implementation/rehydrate-and-finish.md
wc -w skills/plan-to-implementation/rehydrate-and-finish.md
```

Expected: `cmp` exits 0 and the recipe word count is lower than the pre-change 746 words.

- [ ] **Step 3: Write the result record**

Create `results-2026-08-23.md` with:

- resolved basic provider/model;
- exact control and candidate recipe variants;
- per-run S9, T10, and pressure results for both variants;
- aggregate scores and variance observations;
- accepted wording or rejected-candidate rationale;
- command inventory table with documentation URL, installed-help evidence, live-read evidence, and verdict;
- explicit conclusion that broad inspection and body-consuming commands retain `body` in `--json`;
- explicit explanation that comment-based plan extraction intentionally replaced PR-body extraction.

- [ ] **Step 4: Run skill-specific verification**

Run `git diff --check`, confirm `SKILL.md` files are unchanged from `e6a8cea`, and manually verify every command copied into the result record.

- [ ] **Step 5: Commit the skill refactor**

```bash
git add .agents/skills/plan-to-implementation/rehydrate-and-finish.md \
  skills/plan-to-implementation/rehydrate-and-finish.md \
  docs/research/plan-to-implementation-bench/results-2026-08-23.md
git commit -m "Compress plan finish recipe after ablation"
```

### Task 4: Run Repository Quality Gates

**Files:**
- Verify all files changed since `8f93df9`

- [ ] **Step 1: Run unit tests**

Run: `just test-unit`

Expected: 261 tests pass; existing Bats BW02 warnings may remain.

- [ ] **Step 2: Run the full Docker suite**

Run: `just test`

Expected: 54 goss checks and 25 integration tests pass.

- [ ] **Step 3: Verify PR diff and synchronization**

Run:

```bash
git diff --check origin/main...HEAD
git status --short --branch
gh pr checks 174
```

Expected: clean diff, clean branch synchronized with origin after push, and no failed PR checks.
