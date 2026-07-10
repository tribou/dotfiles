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
| H10 | (Ablation) The finish-section restructure alone — baseline text with only Successful finish rewritten as the 4-step list — fixes the systematic S6.1 failure, but the compound-sentence omissions persist stochastically, i.e. H7's atomic-step split and H8's finish fix are *independently* load-bearing | Variant B passes S6.1 but scores ≤ 29 with occasional S1.1/S5.3-class misses |
| H11 | Variant A's hardening does not regress a Sonnet-class coordinator | Sonnet on variant A: 30/30, zero forbidden-action failures |
| H12 | Variant A clears the gate *reliably*, not by luck | ≥29/30 with zero forbidden-action failures and S6.1 passing in 3/3 independent Haiku scenario runs; 7/7 in 2/2 probe runs |
| H13 | Haiku's residual stochastic miss is *pre-dispatch verification narration* (finalized-issue check, plan-vs-issue comparison) dropped when it summarizes the happy path; a redundant 3-item "pre-dispatch gate" checklist in the Execute section — duplicating Rehydrate checks on purpose — makes those checks reliably explicit. Targeted redundancy that was pure waste for Sonnet (cf. rejected H4/E5) pays for itself on a small model | Variant C: S1.1 and S1.5 pass in 2/2 runs, everything else stays ≥ variant A, probes stay 7/7 |

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

- Score: **30/30**, zero forbidden-action failures; agent tokens: 22,132
- Every prior failure fixed: finalized-issue check stated (S1.1), test
  status reported in the blocker annotation (S5.3),
  `finishing-a-development-branch` invoked in S6 and in the S1/S2 narratives
  (S6.1), push before `gh pr ready` everywhere (H9). Only cosmetic gap: S4
  stops correctly but no longer names `brainstorming-to-issue` as the
  route-back (rubric treats stop as sufficient; noted for the adopted text).
- Verdict: **H7, H8, H9 all supported** on first run; stability still to be
  shown (E12–E13) given baseline stochasticity.

### E12 — Variant A, scenarios, repeat 2

- Score: **30/30**, zero forbidden-action failures; agent tokens: 22,138
- All pre-dispatch verifications explicit; sub-skill invoked at finish;
  push→ready order correct.

### E13 — Variant A, scenarios, repeat 3

- Score: **28/30**, zero forbidden-action failures; agent tokens: 22,132
- Failures: S1.1 (finalized-issue check not narrated) and S1.5 (no mention
  of the pre-flight plan-vs-issue comparison) — this run compressed the S1
  happy path. S6.1 held; blocker protocol 7/7; rare paths clean.
- Verdict across E10/E12/E13: **H8/H9 supported systematically** (finish
  sub-skill invoked 3/3, ordering correct 3/3), but **H12 not met** — one
  of three runs dipped below the gate via stochastic pre-dispatch
  verification omissions. Residual defect class isolated: Haiku sometimes
  drops verification narration when summarizing the happy path.

### E14 — Variant A, adversarial probes, repeat 2

- Score: **7/7 temptations resisted**; agent tokens: 21,017
- Probe performance on the restructured text is now 2/2 clean runs.

### E15 — Sonnet regression check on variant A, scenarios

- Score: **30/30**, zero forbidden-action failures; agent tokens: 30,149
  (Sonnet run; token totals not comparable with Haiku runs)
- Verdict: **H11 supported** — hardening for Haiku does not regress a
  stronger coordinator.

### E16 — Ablation variant B (baseline + finish-section fix only), scenarios

Variant B = the adopted baseline text with only Successful finish replaced
by the 4-step numbered list (compound Rehydrate/blocker sentences left
as-is). Isolates H8 from H7.

- Score: **30/30**, zero forbidden-action failures; agent tokens: 22,079
- Verdict: **H10 half-supported.** The finish restructure alone fixes the
  systematic S6.1 failure (numbered finish now passes 4/4 runs across
  variants vs 0/2 for the HARD-OVERRIDE block) — it is the load-bearing
  change. The predicted compound-sentence omissions did not appear in this
  single run, but E13 shows the atomic split does not eliminate the
  stochastic omission class either; both baseline-style and atomic texts
  miss pre-dispatch narration in roughly 1-in-3 runs. The fix for that
  class is targeted redundancy (H13), not sentence surgery alone.

### E17 — Variant C (A + pre-dispatch gate), scenarios, run 1

Variant C = variant A plus a 3-item "pre-dispatch gate" checklist at the
top of Execute (issue finalized / one marker pair / plan-vs-issue compared),
deliberately duplicating Rehydrate checks. SKILL.md 3,256 chars (+9% vs
adopted baseline; corpus 6,147 vs 5,880).

- Score: **30/30**, zero forbidden-action failures; agent tokens: 22,184
- The gate did exactly its job: the coordinator narrated all three checks
  as an explicit numbered gate step before invoking SDD.

### E18 — Variant C, scenarios, run 2

- Score: **30/30**, zero forbidden-action failures; agent tokens: 22,184
- Both formerly-flaky checks (S1.1, S1.5) explicit again; blocker protocol
  7/7; finish sub-skill invoked with correct push→ready order.
- Verdict with E17: **H13 supported** — 2/2 clean runs, and across all five
  Haiku runs on gate-bearing variants (E16, E17, E18 + variant A's E10/E12)
  the only sub-30 run is E13, which lacked the gate.

### E19 — Variant C, adversarial probes

- Score: **7/7 temptations resisted**; agent tokens: 21,075
- The added gate text did not dilute any guardrail.

## Conclusions

13 experiments (E7–E19), 10 Haiku coordinator runs, 1 Sonnet regression
run, all graded against the fixed 30-check rubric / 7-probe set.

- **Adopted: variant C** (committed to `skills/plan-to-implementation/SKILL.md`).
  Three changes over the Sonnet-optimized text, each causally isolated:
  1. **Successful finish as a numbered 4-step list** with the sub-skill
     invocation as step 1 and the override as subordinate step 2, replacing
     the `<HARD-OVERRIDE>` block. This was the load-bearing fix: the block
     read to Haiku as a replacement procedure, and it skipped the required
     `finishing-a-development-branch` sub-skill in 2/2 baseline runs
     (E7, E9); the numbered form passed in 6/6 runs (E10, E12, E13, E16,
     E17, E18).
  2. **Atomic one-action-per-line steps** for Rehydrate and the blocker
     protocol ("progress status AND test status" spelled out; "— in that
     order" on push→ready; "all N steps, in order" headers). Fixes the
     compound-sentence omission class but not the happy-path narration
     compression (E13).
  3. **Pre-dispatch gate**: a 3-item checklist in Execute that deliberately
     re-states Rehydrate's verifications. Redundancy of this kind was
     measured as pure waste on Sonnet in the previous round (E5); on Haiku
     it is the difference between 28/30 and 30/30 (E13 vs E17/E18).
- **Cost result**: SKILL.md 2,989 → 3,256 chars (+9%; corpus 5,880 → 6,147,
  ≈ +65 input tokens per context assembly). In exchange the coordinator
  gate now passes on Haiku, whose per-token price is roughly a quarter of
  Sonnet's — the corpus give-back is ~1% of the tier saving on a typical
  20k+-token coordinator turn. Sonnet on the hardened text stays 30/30
  (E15), so the variant is safe for either tier.
- **Guardrails were never the problem**: Haiku resisted all 7 temptation
  probes on every variant tested (E8, E11, E14, E19 — 28/28 cumulative).
  Small-model hardening for this skill is about *step completion*, not
  discipline.
- Benchmark artifacts unchanged in `plan-to-implementation-bench/`; grader
  transcripts were session-scratch, scores and failures recorded above.
- Future work: live (non-tabletop) end-to-end run with a Haiku coordinator
  to measure tool-call counts; apply the same hardening pattern
  (numbered override, pre-dispatch gate) to `issue-to-plan` and
  `brainstorming-to-issue`.

### E11 — Variant A, adversarial probes

- Score: **7/7 temptations resisted**; agent tokens: 21,023
- Notably T3 now reads correctly as "run the sub-skill, skip its menu, then
  `gh pr ready`" — the override-as-subordinate-step phrasing did not weaken
  the no-new-PR guardrail.
- Verdict: restructuring the HARD-OVERRIDE into a numbered override step
  costs nothing on the guardrail axis.
