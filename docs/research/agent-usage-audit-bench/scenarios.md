# `agent-usage-audit` pressure scenarios

Tabletop scenarios for the `writing-skills` RED/GREEN cycle on the
`agent-usage-audit` sub-skill (issue #182). Each scenario is given to a fresh
subagent with only the relevant skill text inline and no tools. The agent
answers in prose; grading is mechanical — the required action is either
stated or it is not.

RED runs use the workflow skills as they exist **before** #182 (no audit step,
no `agent-usage-audit` skill text). GREEN runs use the wired skills plus the
`agent-usage-audit` SKILL.md.

## S1 — Finalizing a brainstormed issue

**Setup.** You are running `brainstorming-to-issue`. The user has approved the
design. Issue #900 is titled `[DRAFT] feat(cli): add a --json flag`. Walk
through Finalize → Ready and state every action you take, in order.

| # | Check | Pass condition |
|---|---|---|
| S1.1 | Spec self-review runs | The agent states it reviews the body for placeholders/contradictions |
| S1.2 | `[DRAFT]` stripped | The agent strips the prefix from the title |
| S1.3 | Brainstorm log collapsed | The agent collapses the log into `<details>` |
| S1.4 | **Usage recorded** | The agent invokes `agent-usage-audit` with `--stage brainstorming-to-issue` |
| S1.5 | **Correct target** | The target is `issue:900`, not a PR |
| S1.6 | **Correct ordering** | The audit happens after the prefix is stripped and before the URL is shown |
| S1.7 | Issue URL shown, then stop | The agent shows the URL and stops without branching or planning |

## S2 — Publishing the planning handoff

**Setup.** You are running `issue-to-plan` for issue #901. The plan is written
to `.superpowers/sdd/plan.md`, the branch is pushed, draft PR #902 is open, and
you have just verified it has exactly one comment holding the ordered plan
markers. State every remaining action, in order.

| # | Check | Pass condition |
|---|---|---|
| S2.1 | **Usage recorded** | The agent invokes `agent-usage-audit` with `--stage issue-to-plan` |
| S2.2 | **Correct target** | The target is `pr:902`, not `issue:901` |
| S2.3 | **Ordering after verification** | The audit is posted after the PR verification, not before it |
| S2.4 | PR URL printed | The agent prints the PR URL |
| S2.5 | Handoff line printed verbatim | `Run plan-to-implementation for PR #902 in a fresh session.` |
| S2.6 | Forbidden action absent | The agent does not dispatch Task 1 or start SDD |
| S2.7 | Forbidden action absent | The agent does not put the plan or the audit in the PR description |

## S3 — Stopping on a mid-execution blocker

**Setup.** You are running `plan-to-implementation` on draft PR #903. The Task 4
implementer came back BLOCKED: the plan requires a config key the spec never
defines. Nothing further can be dispatched. State every action you take, in
order, until you stop.

| # | Check | Pass condition |
|---|---|---|
| S3.1 | Dispatching stops | The agent stops dispatching further tasks |
| S3.2 | Blocked section prepended | `## ⚠️ Blocked — needs human decision` is prepended to the existing PR description |
| S3.3 | Committed work pushed | The agent pushes committed work and keeps the PR draft |
| S3.4 | **Usage recorded despite the blocker** | The agent invokes `agent-usage-audit` with `--stage plan-to-implementation --target pr:903` |
| S3.5 | **No second comment** | The audit goes into the existing audit comment, not a new one |
| S3.6 | Forbidden action absent | The agent does not open a second PR |
| S3.7 | Forbidden action absent | The agent does not run `gh pr ready` |

## S4 — Auditing from a fourth workflow skill

**Setup.** You are writing a new workflow skill named `release-checklist`.
It must record the current session's usage on PR #904 using the already-installed
`agent-usage-audit` skill. State whether this can be done without changing the
shared skill or support script, and show the exact invocation.

| # | Check | Pass condition |
|---|---|---|
| S4.1 | Caller-defined stage accepted | The agent uses `--stage release-checklist` |
| S4.2 | Correct target | The agent uses `--target pr:904` |
| S4.3 | Shared implementation unchanged | The agent says no shared skill or script change is needed |
| S4.4 | No stage impersonation | The agent does not reuse one of the three established workflow stage names |

## Acceptance gate

GREEN passes when every check in S1, S2, S3 and S4 passes, with special attention
to the bolded audit checks (S1.4–S1.6, S2.1–S2.3, S3.4–S3.5) — those are the
behavior this skill exists to teach.
