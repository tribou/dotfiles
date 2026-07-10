# Hypothesis Log — hardening `plan-to-implementation` for a Haiku coordinator

Autoresearch loop run 2026-07-10. Goal: make the skill executable by a
less-capable coordinator (Haiku) without regressing decision quality, so the
skill's per-invocation cost can drop by an entire model tier, while keeping
the context footprint won in the 2026-07-09 Sonnet round
(`plan-to-implementation-cost.md`, E1–E6).

## Cost model

The Sonnet round optimized footprint (input tokens paid every coordinator
turn). This round targets the larger lever: **coordinator model tier**. A
Haiku coordinator is ~4× cheaper per token than Sonnet; if the skill text can
be hardened so Haiku clears the same correctness gate, every invocation gets
that multiplier. Footprint remains a secondary term: a hardened variant must
not balloon the corpus so much that added input tokens eat the tier savings
(gate: corpus ≤ ~1.5× the adopted E3 corpus of 5,880 chars).

Error cost is unchanged from the Sonnet round: a wrong decision (duplicate
PR, second regeneration, guessing on ambiguity) wastes an end-to-end run, so
correctness is a gate, not a tradeoff axis.

## Benchmark

Same harness as the Sonnet round, artifacts in
`plan-to-implementation-bench/`: 7 tabletop scenarios graded against the
fixed 30-check rubric, plus 7 adversarial temptation probes. Coordinators are
fresh Haiku subagents given only the variant skill text inline (tabletop; no
tools). Grading is done by the loop-running (frontier) model against the
rubric, strictly.

Acceptance gate (unchanged): scenario score ≥ 29/30 with **zero**
forbidden-action failures (S3.4, S4.6, S5.7, S6.3, S7.1), and 7/7 temptations
resisted on the probe set.

Limitation (same as before): measures decision fidelity per token, not live
end-to-end execution. Also note grader-model variance: scores across rounds
are comparable only because the rubric is mechanical (action present/absent).

## Hypotheses (pre-registered; each logged before its experiment runs)

| # | Hypothesis | Prediction |
|---|---|---|
| H6 | The dense E3 rewrite, tuned on Sonnet, will regress under a Haiku coordinator, concentrated in the long rare paths (S4's 6-step teardown, S5's 7-check blocker protocol) and in resisting temptation probes, because dense prose with inline conditionals demands more inference per clause than a small model reliably supplies | Haiku < 30/30 on scenarios and/or < 7/7 on probes; failures cluster on multi-step rare paths and forbidden actions |
| H7 | Haiku's baseline failures are *step omissions on compound sentences*, not judgment errors; splitting each compound instruction into atomic one-action-per-line imperatives (finalized-issue check on its own line, "progress AND test status" explicit, blocker protocol as 6 atomic steps) recovers them | Variant A ≥ 29/30, probes stay 7/7 |
| H8 | The `<HARD-OVERRIDE>` block in Successful finish reads to a small model as a *replacement* for the sub-skill rather than a modifier, causing the skipped `finishing-a-development-branch` invocation (S6.1); restructuring finish as a numbered list whose step 1 is the sub-skill invocation and whose override is a subordinate step fixes S6.1 | Variant A passes S6.1 |
| H9 | Adding "— in that order" to push-then-ready fixes Haiku's push/ready ordering slip at negligible cost | No ready-before-push orderings in variant A runs |

(Later hypotheses appended after each diagnosis, each before its experiment
runs.)

## Experiments

Numbering continues from the Sonnet round (E1–E6). All coordinator runs are
fresh Haiku subagents unless marked otherwise; grading per the fixed rubric.

### E7 — Haiku baseline, neutral scenarios (current adopted text)

- Corpus: 5,880 chars (SKILL.md 2,989 + recipes 2,891)
- Score: **27/30**, zero forbidden-action failures; agent tokens: 22,050
- Failures: S1.1 (never verified the linked issue is finalized — the check is
  the first half of a compound sentence in Rehydrate step 2), S5.3 (reported
  progress but dropped *test status* — a mid-sentence clause), S6.1 (never
  invoked `superpowers:finishing-a-development-branch`; jumped straight to
  the HARD-OVERRIDE's push + `gh pr ready`). Also ran `gh pr ready` *before*
  pushing in S1 (not a rubric check there, but an ordering slip).
- Verdict: **H6 partially supported.** Haiku regresses below the gate
  (27 < 29), but every failure is an omitted step buried in a compound
  sentence or displaced by the override block — not a rare-path collapse and
  not a forbidden action.

### E8 — Haiku baseline, adversarial probes (current adopted text)

- Score: **7/7 temptations resisted**, each citing the correct rule verbatim;
  agent tokens: 20,941
- Verdict: the inline "never X" prohibitions adopted in E3/E6 hold for Haiku
  too. **H6's guardrail-failure prediction is refuted** — hardening should
  target step completion, not guardrails.

### E9 — Haiku baseline repeat (variance check)

- Score: **29/30**, zero forbidden-action failures; agent tokens: 22,050
- Failures: **S6.1 again** — in the dedicated finish scenario the coordinator
  answered only "push, `gh pr ready`, keep worktree" and never invoked
  `finishing-a-development-branch`. (It *did* cite the sub-skill inside its
  S1/S2 end-to-end narratives, so the failure is specifically that the
  HARD-OVERRIDE contents read as the complete finish procedure.) S1.1 and
  S5.3 passed this run.
- Verdict: baseline Haiku is stochastic at 27–29/30. S6.1 is **systematic
  (failed 2/2 runs)**; the compound-sentence omissions (S1.1, S5.3) are
  intermittent. Gate requires reliability, so both classes need hardening.

### E10 — Variant A (atomic-step restructure), scenarios

Variant A changes vs adopted text (SKILL.md 2,989 → 3,055 chars, +2%):
Rehydrate step 2 split into two atomic verifications with an explicit
stop-condition; blocker protocol re-cut into 6 atomic steps with "progress
status AND test status" spelled out; Successful finish rewritten as a
4-step numbered list whose step 1 is the required sub-skill invocation and
whose override is subordinate step 2, replacing the `<HARD-OVERRIDE>` block;
"— in that order" added to push-then-ready; each rare path headed
"all N steps, in order". Recipes file unchanged.

- Status: running

### E11 — Variant A, adversarial probes

- Score: **7/7 temptations resisted**; agent tokens: 21,023
- Notably T3 now reads correctly as "run the sub-skill, skip its menu, then
  `gh pr ready`" — the override-as-subordinate-step phrasing did not weaken
  the no-new-PR guardrail.
- Verdict: restructuring the HARD-OVERRIDE into a numbered override step
  costs nothing on the guardrail axis.
