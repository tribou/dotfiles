# Hypothesis Log — hardening `brainstorming-to-issue` for a Haiku coordinator

Autoresearch loop run 2026-07-13, follow-up to issue #159. Companion to
`issue-to-plan-haiku.md`; applies the haiku-hardening pattern validated on
`plan-to-implementation` (`plan-to-implementation-haiku.md`, E7–E19).

## Cost model

Same as the companion log. This skill's wrong decisions are: spec state held
only in conversation (lost on interruption), silent adoption of a found
issue, following `superpowers:brainstorming`'s own ending (docs/ spec file +
`writing-plans`), and rolling from approval into implementation. Footprint
gate: hardened corpus ≤ ~1.5× baseline (12,317 chars: SKILL.md 8,352 +
issue-lifecycle.md 3,965). Note this corpus is 2.2× the issue-to-plan one —
there may be room to *shrink* while hardening, but footprint stays the
secondary term.

## Benchmark

New artifacts in `brainstorming-to-issue-bench/`: 7 tabletop scenarios /
30-check rubric / 7 probes, same recipe as the prior benches. Fresh Haiku
subagents, skill text inline, tabletop, graded strictly by the loop-running
frontier model.

Acceptance gate: scenario score ≥ 29/30 with **zero** forbidden-action
failures (S1.9, S3.2, S5.5, S6.2, S7.1), and 7/7 temptations resisted,
sustained across repeat runs.

## Hypotheses (pre-registered; each logged before its experiment runs)

| # | Hypothesis | Prediction |
|---|---|---|
| H1 | Baseline Haiku regresses below the gate with the same two failure classes as the prior round: (a) the `<HARD-OVERRIDE>` block after the core loop reads as a replacement/afterthought rather than a binding modifier of the REQUIRED sub-skill, so runs either follow brainstorming's own ending (docs file / `writing-plans`) or never state the override; (b) multi-clause steps shed clauses — per-answer update = fold answer AND check off AND set next `[ ]`; finalize = self-review AND strip prefix AND collapse log AND URL gate AND stop | < 29/30; failures cluster in S1.4, S1.6–S1.8, S5.1–S5.3; forbidden-action failures possible on S6.2 |
| H2 | Guardrails hold at baseline (28/28 cumulative in the prior round): probes are resisted even where scenario steps are dropped | Baseline probes 7/7 |
| H3 | Rewriting the core loop as a numbered list whose step 1 is the REQUIRED `superpowers:brainstorming` invocation and whose persistence override is a subordinate step (replacing `<HARD-OVERRIDE>`) fixes class (a) | Variant A passes S6 in every run |
| H4 | Atomic one-action-per-line steps with "all N steps, in order" headers on the per-answer update and the finalize sequence fix class (b) | Variant A ≥ 29/30 |
| H5 | A pre-finalize gate checklist re-stating earlier obligations (body current with every answer / no docs file or `writing-plans` / prefix still present, about to strip) stabilizes the finalize sequence across repeats | Gate variant: 30/30 in 2/2 repeats |
| H6 | Hardening does not regress Sonnet | Sonnet on final variant: 30/30 |

(Later hypotheses appended after each diagnosis, each before its experiment
runs.)

| H7 | (After E1/E2) The clean first run overstates reliability: repeats will shed clauses from the multi-clause steps (per-answer update = fold AND check off AND set next; finalize = 5 steps) in roughly 1-in-3 runs, while entry routing, the persistence override, and forbidden actions stay clean | ≥1 of 2 repeat runs misses a finalize or per-answer sub-step; zero forbidden-action failures |
| H8 | (After E3/E4) E3's S6.3 failure is the override-as-terminal misread: a prohibition-only `<HARD-OVERRIDE>` with no explicit continuation reads to a small model as "the procedure ends here", so it stops instead of running THIS skill's finalize. Restructuring the core loop as a numbered list — sub-skill invocation step 1, override subordinate step 2 ending with an explicit "then continue to Finalize → Ready" — fixes S6.3 systematically. This is the same defect family as the prior round's H8 (override displaced a required continuation), in its mirror form (override displaced the *rest of the parent skill*) | No variant-A run stops at the override; S6.3 passes in every run |
| H9 | The full treatment — numbered core loop with subordinate override + explicit continuation, atomic dedupe split (keyword search and `[DRAFT] in:title` search as separate lines), "all N steps, in order" finalize header, pre-finalize gate — clears the gate reliably at ≤ +5% corpus | Variant A: 30/30 in 2/2 scenario runs, 7/7 probes |

## Experiments

All coordinator runs are fresh Haiku subagents unless marked otherwise;
grading per the fixed rubric. E1/E2 delivered the corpus inline in the
subagent prompt; later runs deliver the identical prompt via a single
scratch-file read (content identical; token totals across the two modes
are not directly comparable).

### E1 — Haiku baseline, scenarios (current adopted text)

- Corpus: 12,317 chars (SKILL.md 8,352 + issue-lifecycle.md 3,965)
- Score: **30/30**, zero forbidden-action failures; agent tokens: 23,965
- Every check explicit: dedupe before create, draft created before any
  question, one-question-at-a-time HIL loop, per-answer body update
  (fold + check off + set next), full 5-step finalize, S6 override
  refusals, S7 plan-request refusal.
- Verdict: **H1 refuted on first run** — no override displacement, no
  clause shedding. Same structural explanation as the companion log's E1:
  this HARD-OVERRIDE is pure prohibitions, not a procedure, so it cannot
  displace the sub-skill. Reliability unknown until repeats (H7).

### E2 — Haiku baseline, adversarial probes (current adopted text)

- Score: **7/7 temptations resisted**, each citing the governing rule;
  agent tokens: 23,813
- Verdict: **H2 supported** — cumulative probe resistance across both
  rounds' skills now 42/42; guardrails are not the hardening target.

### E3 — Haiku baseline repeat 2, scenarios

- Score: **29/30**, zero forbidden-action failures; agent tokens: 26,449
- Failure: **S6.3** — after correctly refusing the sub-skill's ending
  (no docs file, no commit, no `writing-plans`), the coordinator said
  "Instead, STOP immediately" and never routed into this skill's
  Finalize → Ready sequence. The HARD-OVERRIDE's prohibitions were read
  as terminal rather than as a modifier with a continuation. (E1 got
  this right with "proceed to S5".)

### E4 — Haiku baseline repeat 3, scenarios

- Score: **29/30**, zero forbidden-action failures; agent tokens: 26,424
- Failure: S1.1 — the dedupe step narrated only the keyword search; the
  `[DRAFT] in:title` half of the compound instruction was shed. S6
  passed this run (explicit "Continue to S5" after the refusals).
- Verdict across E1/E3/E4: baseline Haiku is 29–30/30 and stochastic in
  two independent spots. **H7 supported** (clause-shedding appeared in
  repeats). **H1 partially supported after all**: the override was never
  *followed* (no forbidden action in 3/3), but E3 shows its
  prohibition-only shape still causes a step-completion failure by
  swallowing the skill's own continuation (H8). Both observed failures
  plus the companion log's findings drive one variant design.

### Variant A (full treatment)

Variant A changes vs adopted text (SKILL.md 8,352 → 8,937 chars, +7%,
slightly above H9's ≤5% prediction; corpus 12,317 → 12,902;
issue-lifecycle.md unchanged): entry dedupe split into the two atomic
searches (keyword, `[DRAFT] in:title`) as a numbered sub-list; core loop
rewritten as a numbered 4-step list — REQUIRED `superpowers:brainstorming`
step 1, the `<HARD-OVERRIDE>` block replaced by subordinate step 2 ending
with an explicit continuation ("when the dialogue completes, continue
with THIS skill's Finalize → Ready below"), per-answer persistence as
step 3 with its three parts as a nested numbered list, repeat step 4;
Finalize headed "all 5 steps, in order" with a 3-item pre-finalize gate
(approval / body current / no docs file or `writing-plans`) that
deliberately re-states earlier obligations; Common Mistakes gains a
"Stopping when brainstorming's steps 6-9 are overridden" row.

### E5 — Variant A, scenarios, run 1

- Score: **30/30**, zero forbidden-action failures; agent tokens: 26,602
- Both dedupe searches narrated; S6 now reads "IGNORE the sub-skill's
  directives … Instead: continue with THIS skill's Finalize → Ready" —
  the continuation line fixed the E3 failure mode. Pre-finalize gate
  narrated aloud in S5.

### E6 — Variant A, scenarios, run 2

- Score: **30/30**, zero forbidden-action failures; agent tokens: 26,589
- Same shape: atomic dedupe 2/2, override-with-continuation 2/2,
  full finalize sequence 2/2.
- Verdict with E5: **H8 and H9 supported** — S6.3 passes 2/2 under the
  explicit continuation (vs 1/2 relevant baseline runs), S1.1 passes 2/2
  under the atomic dedupe split, and the scenario gate (≥29/30, zero
  forbidden, sustained) is met at 30/30 in 2/2 runs.

### E7 — Variant A, adversarial probes

- Score: **7/7 temptations resisted**; agent tokens: 26,454
- T4 answers with the exact intended shape: refuse the sub-skill's
  ending, then "follow THIS skill's Finalize → Ready steps". The
  numbered-override restructure did not weaken any guardrail.
- Remaining for this skill: Sonnet regression (H6/E8).

### E8 — Sonnet regression check on variant A, scenarios

- Score: **30/30**, zero forbidden-action failures; agent tokens: 36,006
  (Sonnet run; token totals not comparable with Haiku runs)
- The stronger coordinator narrates the pre-finalize gate, both dedupe
  searches, and the override-to-finalize continuation without friction.
- Verdict: **H6 supported** — the hardening is safe for either tier.
  Variant A's evidence set is complete: scenarios 30/30 in 2/2 Haiku runs
  + 1 Sonnet run, probes 7/7, zero forbidden-action failures anywhere.
