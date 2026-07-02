---
name: issue-to-implementation
description: Use when implementing a finalized (non-[DRAFT]) GitHub issue that already holds the agreed spec — turning that issue into working code in this session. Triggers include "implement issue #N", "build out issue #N", "take issue #N to code", "execute the finalized issue", "start building the spec in issue #N". Not for drafting or refining the spec itself (that is brainstorming-to-issue), and not for a change small enough to be a single test-and-commit.
---

# Issue → Implementation

## Overview

Take a finalized GitHub issue (the durable **what/why** spec produced by `brainstorming-to-issue`) and drive it to merged code — **without** a committed plan document and **without** a human approval gate on the plan. Plan *generation* is delegated wholesale to `superpowers:writing-plans`; only its **persistence** (where the plan lives) and its **handoff** (who decides how to execute) are overridden.

**Core principle:** the issue is the durable spec; the plan is ephemeral **how**. So the plan lives in per-run scratch and is mirrored into the PR description at the end — never committed under `docs/`. Execution auto-hands to `superpowers:subagent-driven-development`; there is no "which approach?" question. And when the branch finishes, the outcome is pre-decided too: always push and open the PR — there is no "what would you like to do?" question either.

This is the exact inverse of `brainstorming-to-issue`: that skill reuses brainstorming's dialogue but diverts its *docs/ + writing-plans* tail into an issue; **this** skill reuses writing-plans' *generation* but diverts its *docs/ + human-choice* tail into scratch + auto-SDD.

## When to Use

- A finalized (non-`[DRAFT]`) issue exists and you're ready to build it now.
- The work is more than one test-and-commit: multiple files, or two-plus independently reviewable deliverables, or interfaces between units.

**When NOT to use:**
- The issue is still `[DRAFT]` or the spec isn't settled → use `superpowers:brainstorming` / `brainstorming-to-issue` first.
- The change is trivial (see the gate below) → skip planning entirely and go straight to `superpowers:test-driven-development`.

## Entry Gate

Decide **before** generating anything.

```dot
digraph entry {
    "Issue finalized (no [DRAFT])?" [shape=diamond];
    "Route to brainstorming-to-issue" [shape=box];
    "One file + one behavior, gated in a single review pass?" [shape=diamond];
    "Skip plan: inline TDD against the issue" [shape=box];
    "Link the issue, then generate the plan" [shape=doublecircle];

    "Issue finalized (no [DRAFT])?" -> "Route to brainstorming-to-issue" [label="no"];
    "Issue finalized (no [DRAFT])?" -> "One file + one behavior, gated in a single review pass?" [label="yes"];
    "One file + one behavior, gated in a single review pass?" -> "Skip plan: inline TDD against the issue" [label="yes"];
    "One file + one behavior, gated in a single review pass?" -> "Link the issue, then generate the plan" [label="no"];
}
```

**Triviality predicate (observable):** the whole change is one file touched, one logically independent behavior, and a single reviewer could gate it in one red-green-commit pass. If you're unsure whether it splits into 2+ reviewable units, that uncertainty means it is **not** trivial — plan it. Never skip the plan just because the issue text is short.

## Link the Issue First

Before generating the plan, bind to the real tracker item (this is where ad-hoc runs drift):

1. `gh issue view <N>` — confirm it is the finalized spec and carries no `[DRAFT]` prefix. If it does, stop and route to `brainstorming-to-issue`.
2. Claim it per this repo's rule: add the `in-progress` label.
3. Record `Closes #<N>` — it goes in the PR body at the end.

Exact commands: `plan-and-dispatch.md`.

## Generate the Plan (delegated, then diverted)

**REQUIRED SUB-SKILL:** Run `superpowers:writing-plans` to generate the plan from the issue body — File Structure, Task Right-Sizing, **Global Constraints copied verbatim from the issue's requirements**, per-task Interfaces (Consumes/Produces), bite-sized TDD steps, and its Self-Review. Generate it exactly as that skill describes.

<HARD-OVERRIDE>
`superpowers:writing-plans` ends by saving to `docs/superpowers/plans/YYYY-MM-DD-<name>.md`, committing, and offering the human an execution choice ("Which approach?"). When using THIS skill you do NONE of that:

- Do NOT save the plan under `docs/`. Write it to **`.superpowers/sdd/plan.md`** inside the execution worktree (the same git-ignored scratch dir SDD already uses for briefs and its progress ledger). Ensure the path is ignored via SDD's nested-ignore convention — never by editing the tracked root `.gitignore` (see `plan-and-dispatch.md`).
- Do NOT commit the plan. It is scratch, not a tracked artifact. Its durable home is the PR description, added at the end.
- Do NOT ask "which execution approach?" — there is no human gate here. Auto-select subagent-driven execution.

The issue is the durable *what*; this scratch plan is the ephemeral *how*.
</HARD-OVERRIDE>

## Auto-Handoff to Execution

**REQUIRED SUB-SKILL:** Use `superpowers:subagent-driven-development`, pointing its `scripts/task-brief` at `.superpowers/sdd/plan.md`. Do not pause for approval between generating the plan and dispatching Task 1 — the human already approved at issue finalization.

SDD ends via `superpowers:finishing-a-development-branch`, which opens the PR. **The PR description MUST contain the plan (the ephemeral how) and `Closes #<N>`** — that is where the plan becomes durable. It never returns to `docs/` and never lands on the issue.

<HARD-OVERRIDE>
`superpowers:finishing-a-development-branch` is built to **present a completion menu** ("Implementation complete. What would you like to do? 1. Merge locally / 2. Push and create a Pull Request / 3. Keep as-is / 4. Discard") and to treat asking the human as the correct behavior. When reached through THIS skill, that choice is already made — the human approved at issue finalization, and this skill's whole contract is that the PR is the plan's durable home.

So do NOT surface that menu. Auto-select **"Push and create a Pull Request"** and proceed straight to pushing the branch and opening the PR. Select it by its label, not its number: it is option **2 in a normal repo** but option **1 on a detached HEAD**. Run every other finishing step (verify tests, detect environment, keep the worktree) exactly as that skill describes — only the human choice at its option menu is overridden.
</HARD-OVERRIDE>

## Common Mistakes

| Mistake | Fix |
|---|---|
| Saving the plan to `docs/superpowers/plans/` (writing-plans' default) | Divert to `.superpowers/sdd/plan.md` per HARD-OVERRIDE |
| Committing the plan file | Never commit it — it's scratch; it goes in the PR body at the end |
| Asking the human "which execution approach?" | No plan gate — auto-hand to subagent-driven-development |
| Surfacing finishing-a-development-branch's "what would you like to do?" menu | No finishing gate — auto-select "Push and create a Pull Request" |
| Re-deriving task decomposition by hand | Delegate generation entirely to `writing-plans` — don't reinvent it |
| Planning a trivial one-file change | Apply the entry gate — trivial ⇒ inline TDD, no plan, no SDD |
| Building a `[DRAFT]` issue | Not finalized — route back to `brainstorming-to-issue` |
| Never claiming / linking the real issue | `gh issue view <N>`, add `in-progress` label, carry `Closes #<N>` to the PR |
| Plan ends up nowhere durable (only in lost context) | Mirror it into the PR description via the finishing step |

## Red Flags — STOP

- About to write the plan under `docs/` or `git commit` it
- About to ask the human to pick an execution mode
- About to show finishing-a-development-branch's completion menu instead of auto-selecting the PR option
- About to hand SDD an issue with no plan file, or re-derive tasks yourself
- Running full plan + SDD on a change that's one file and one behavior
- The issue title still says `[DRAFT]`
- The plan exists only in conversation with no `.superpowers/sdd/plan.md` on disk

All of these mean: divert the plan to scratch, keep the human out of both gates (execution approach and branch finishing — always PR), and let the issue (durable what) and PR (durable how) be the only persisted artifacts.
