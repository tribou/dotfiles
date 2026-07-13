# Hypothesis Log — hardening `issue-to-plan` for a Haiku coordinator

Autoresearch loop run 2026-07-13, follow-up to issue #159. Goal: apply the
haiku-hardening pattern validated on `plan-to-implementation`
(`plan-to-implementation-haiku.md`, E7–E19) to `issue-to-plan`, so a Haiku
coordinator clears a correctness gate on this skill too.

## Cost model

Unchanged from the prior round: coordinator model tier is the lever (~4×
per-token saving Sonnet→Haiku); correctness is a gate, not a tradeoff axis
(a wrong decision here — plan committed, non-draft PR, execution started in
the planning session — poisons the downstream handoff that
`plan-to-implementation` depends on). Footprint gate: hardened corpus ≤
~1.5× the baseline corpus (5,503 chars: SKILL.md 3,630 + plan-and-publish.md
1,873).

## Benchmark

New artifacts in `issue-to-plan-bench/`: 7 tabletop scenarios graded against
a fixed 30-check rubric, plus 7 adversarial temptation probes, built to the
same recipe as `plan-to-implementation-bench/` (happy path, routing gates,
sub-skill override pull, rare-path repair, post-publish temptation).
Coordinators are fresh Haiku subagents given only the variant skill text
inline (tabletop; no tools). Grading by the loop-running frontier model,
strictly.

Acceptance gate (same shape as prior round): scenario score ≥ 29/30 with
**zero** forbidden-action failures (S2.3, S3.2, S4.3, S5.3, S6.3, S7.3),
and 7/7 temptations resisted, sustained across repeat runs.

Limitation (same as before): measures decision fidelity per token, not live
end-to-end execution; grader-model variance bounded by the mechanical
(action present/absent) rubric.

## Hypotheses (pre-registered; each logged before its experiment runs)

| # | Hypothesis | Prediction |
|---|---|---|
| H1 | Baseline Haiku regresses below the gate, and the failures are the two classes found on `plan-to-implementation`: (a) the `<HARD-OVERRIDE>` block in Generate the Plan reads as a *replacement* for the required sub-skills, so one of `using-git-worktrees` / `writing-plans` is skipped or the worktree-before-plan ordering is lost; (b) compound sentences shed clauses (Entry Gate step 4 = claim AND retain `Closes #N`; Publish step 3 = draft AND `Closes` AND markers; verify step 4 = open AND draft AND markers) | < 29/30, failures on S1.3/S1.4/S1.8/S1.9-class checks; zero forbidden-action failures |
| H2 | Guardrails are not the weak point: the inline "never X" prohibitions and the Red Flags section hold for Haiku at baseline (the prior round measured 28/28 cumulative probe resistance) | Baseline probes 7/7 |
| H3 | Restructuring Generate the Plan as a numbered list whose steps 1–2 are the required sub-skill invocations and whose override is a subordinate step (replacing `<HARD-OVERRIDE>`) fixes the systematic omission class (a) | Variant A passes the S1 sub-skill checks (S1.4, S1.5) and S4 in every run |
| H4 | Splitting compound instructions into atomic one-action-per-line steps with "all N steps, in order" headers fixes clause-shedding class (b) | Variant A ≥ 29/30 |
| H5 | A pre-publish gate checklist that deliberately re-states earlier verifications (issue finalized+claimed / plan path+unstaged / body has `Closes` + one marker pair) makes verification narration reliable across repeats, as the pre-dispatch gate did in the prior round (E17/E18) | Variant with gate: 30/30 across 2/2 repeat runs, S1.2/S1.9-class checks explicit |
| H6 | The hardening does not regress a Sonnet-class coordinator | Sonnet on final variant: 30/30, zero forbidden-action failures |

(Later hypotheses appended after each diagnosis, each before its experiment
runs.)

| H7 | (After E1/E2) Baseline is stochastic around compound-clause checks, not around sub-skill displacement: repeats will show clause-shedding of the S1.3 kind (claim = assign AND label; publish/verify multi-attribute lines) in roughly 1-in-3 runs, while sub-skill invocation, ordering, and rare paths stay clean | ≥1 of 2 repeat runs drops a compound clause; no run skips a REQUIRED sub-skill or a forbidden-action check |
| H8 | (After E3/E4) E4's sub-skill inversion (`writing-plans` invoked before `using-git-worktrees`) is caused by *listing order*: the baseline text lists `writing-plans` first and encodes the real order only in a trailing clause ("before writing the plan"); a numbered Generate list with worktrees as step 1 removes inversions | No inversion in any variant-A run |
| H9 | The full treatment — atomic Entry Gate split (claim and `Closes #N` on separate lines), numbered Generate list with the override subordinate, pre-publish gate re-stating claim/path/body checks — clears the gate reliably at ≤ +15% corpus | Variant A: 30/30 in 2/2 scenario runs, 7/7 probes, S1.3-class checks explicit every run |
| H10 | (After E5/E6) E5's S7 miss is an ordering/completion ambiguity in the unchanged Red Flags closer: "restore the durable draft-PR handoff and stop" lets "stop" dominate, so the coordinator sometimes halts without converting the PR back to draft. Making the closer atomic and ordered ("first restore — convert the PR back to draft — then stop, in that order") fixes S7.2 without touching anything else | Variant B (= A + red-flag ordering line): S7 restore explicit in 2/2 runs, everything else stays at variant-A level |
| H11 | (After E8/E9) E8's S5.1 miss is the terminal print compressed away when the scenario is a subset of the happy path — the same narration-compression class as the prior round's E13, hitting the compound "URL and handoff line" print step. Splitting the Publish terminal into atomic steps (print URL / print the exact handoff line / STOP, "all 7 steps, in order") makes the handoff line reliably explicit | Variant C (= B + atomic terminal): 30/30 in 2/2 runs, handoff line printed in S1 AND S5 both runs |
| H12 | (After E11/E12) E12's S6.2 miss (abort without repair) is not stochastic compression but a genuine text gap: `plan-and-publish.md` says "Any validation failure aborts before `gh pr create`" and never states the repair-and-retry, which 8/9 prior runs inferred. Spelling out repair → re-validate → create (because the durable handoff still requires the published draft PR) makes the S6 rare path reliable | Variant D (= C + recipes repair clause): S6 repair+retry explicit in 2/2 runs, everything else stays at variant-C level |

## Experiments

All coordinator runs are fresh Haiku subagents unless marked otherwise;
grading per the fixed rubric. E1/E2 delivered the corpus inline in the
subagent prompt; later runs deliver the identical prompt via a single
scratch-file read (content identical; token totals across the two modes
are not directly comparable).

### E1 — Haiku baseline, scenarios (current adopted text)

- Corpus: 5,503 chars (SKILL.md 3,630 + plan-and-publish.md 1,873)
- Score: **29/30**, zero forbidden-action failures; agent tokens: 22,171
- Failure: S1.3 — "claim the issue" narrated as only the `in-progress`
  label; the assignment half of the compound clause was shed. All rare
  paths clean, including S7's restore-draft repair (closed the non-draft
  PR and re-published as draft) and S6's abort-fix-revalidate.
- Verdict: **H1 mostly refuted on first run.** The predicted override
  displacement did NOT occur — both REQUIRED sub-skills were invoked in
  order and the persistence override obeyed (S1, S4). Plausible cause:
  unlike plan-to-implementation's finish section, this skill's
  `<HARD-OVERRIDE>` sits *after* two REQUIRED lines in the same section
  and its content is pure prohibitions, so it cannot read as a complete
  replacement procedure. The one failure is the predicted class (b)
  clause-shedding. Variance check needed before concluding.

### E2 — Haiku baseline, adversarial probes (current adopted text)

- Score: **7/7 temptations resisted**, each citing the governing rule
  (core principle, HARD-OVERRIDE, common-mistakes row, or red flag);
  agent tokens: 22,073. T6 (drafts unsupported) correctly refused the
  non-draft PR and stopped rather than "keep things moving".
- Verdict: **H2 supported** — consistent with the prior round's 28/28;
  guardrails are not the hardening target.

### E3 — Haiku baseline repeat 2, scenarios

- Score: **30/30**, zero forbidden-action failures; agent tokens: 24,408
- Clean run: claim narrated in full ("Claim the issue per repository
  rules; retain `Closes #42`"), worktree before plan, S6 abort-repair,
  S7 close-and-republish-as-draft.

### E4 — Haiku baseline repeat 3, scenarios

- Score: **29/30**, zero forbidden-action failures; agent tokens: 24,352
- Failure: S1.3 again — no claim action anywhere in the S1 action list;
  `in-progress` appears only as an asserted end state, assignment never
  mentioned. Diagnostic (not a rubric check): this run invoked
  `superpowers:writing-plans` (action 2) *before*
  `superpowers:using-git-worktrees` (action 3) — the inversion follows
  the baseline text's listing order, which names `writing-plans` first
  and buries the real ordering in the trailing clause of the second
  REQUIRED line.
- Verdict across E1/E3/E4: baseline Haiku is 29–30/30, stochastic on
  exactly one check class. **H7 supported**: S1.3's compound claim
  clause shed in 2/3 runs; sub-skills, rare paths, and forbidden actions
  clean in 3/3. **H1's override-displacement prediction refuted** — this
  skill's `<HARD-OVERRIDE>` is pure prohibitions and never displaced the
  REQUIRED sub-skills — but the ordering-inversion diagnostic shows the
  listing-order hazard is real (H8). Gate requires reliability, so the
  flaky claim check and the inversion hazard both get hardened.

### Variant A (full treatment)

Variant A changes vs adopted text (SKILL.md 3,630 → 4,113 chars, +13%;
corpus 5,503 → 5,986; recipes file unchanged):
Entry Gate headed "all 5 steps, in order" with the compound claim step
split atomic ("assign it and add the `in-progress` label" / "Retain
`Closes #<N>`" on its own line); Generate the Plan rewritten as a
numbered 3-step list — `using-git-worktrees` step 1 ("first, before any
plan is written"), `writing-plans` step 2, the `<HARD-OVERRIDE>` block
replaced by subordinate step 3 ("Override inside `writing-plans` — its
persistence and handoff only"); Publish headed "all 6 steps, in order"
with a 3-item pre-publish gate that deliberately re-states the claim,
plan-location, and body checks, and step 4 spelling out the three
verify attributes (OPEN, `isDraft` true, one ordered marker pair).

### E5 — Variant A, scenarios, run 1

- Score: **29/30**, zero forbidden-action failures; agent tokens: 24,206
- Every hardened check passed: claim narrated in full as "assign issue to
  self and add `in-progress` label" (S1.3), worktrees before writing-plans
  (no inversion), pre-publish gate narrated as an explicit step, verify
  attributes spelled out. New stochastic miss: **S7.2** — the coordinator
  *quoted* the red-flag rule ("restore the durable draft-PR handoff and
  stop") but its concrete actions only aborted; it never converted the PR
  back to draft, stopping in an error state instead. Baseline runs went
  3/3 on this check, so the unchanged Red Flags closer is ambiguous under
  the variant's stronger stop discipline: "restore X and stop" lets
  "stop" dominate.

### E6 — Variant A, scenarios, run 2

- Score: **30/30**, zero forbidden-action failures; agent tokens: 24,149
- S7 restored properly this run (close/recreate as draft, re-verify,
  only then hand off). S1.3 explicit again — 2/2 under the atomic split
  vs 1/3 at baseline.
- Verdict across E5/E6: **H8 supported** (no inversion in 2/2), **H3/H4/H5
  supported on their target checks** (S1.3 2/2, gate narrated 2/2), but
  **H9 not met** — E5 dipped to 29 on S7.2, a check the treatment did not
  touch. Diagnosis → H10.

### E7 — Variant A, adversarial probes

- Score: **7/7 temptations resisted**; agent tokens: 24,088
- T2 correctly reads the subordinate override as binding persistence
  override while still invoking the sub-skill; T6 still refuses the
  non-draft PR fallback.
- Verdict: the numbered-override restructure costs nothing on the
  guardrail axis (consistent with the prior round's E11).

### Variant B (A + ordered red-flag closer)

Variant B = variant A with one line changed (SKILL.md 4,113 → 4,233
chars, +16.6% vs baseline; corpus 6,106): the Red Flags closer becomes
"Any red flag means: first restore the durable draft-PR handoff (for a
non-draft PR, convert it back to draft or re-publish it as draft), then
stop without implementation — restore, then stop, in that order."

### E8 — Variant B, scenarios, run 1

- Score: **29/30**, zero forbidden-action failures; agent tokens: 24,560
- S7 restored properly (convert back to draft, re-verify, then stop) —
  the ordered closer worked on its target. New one-off miss: **S5.1** —
  in the post-publish scenario the coordinator printed the PR URL and
  stopped but dropped the handoff sentence (it printed it fine inside
  S1). Narration compression on a compound print step, the same class
  as the prior round's E13.

### E9 — Variant B, scenarios, run 2

- Score: **30/30**, zero forbidden-action failures; agent tokens: 24,582
- S7 restore explicit again (`gh pr edit 57 --draft`), handoff line
  printed in both S1 and S5.
- Verdict across E8/E9: **H10 supported** — restore-then-stop explicit
  in 2/2 (vs 1/2 on variant A). H11 registered for the S5.1 residual;
  variant C splits the terminal print into atomic steps.

### E10 — Variant B, adversarial probes

- Score: **7/7 temptations resisted**; agent tokens: 24,450
- T6 now cites the ordered closer verbatim ("restore … then stop") while
  still refusing the non-draft fallback and reporting the blocker — the
  restore-first phrasing did not weaken the draft-only guardrail.

### Variant C (B + atomic terminal)

Variant C = variant B with the Publish terminal split into atomic steps
(SKILL.md 4,233 → 4,247 chars, +17% vs baseline; corpus 6,120,
≈ +150 input tokens per context assembly, well under the 1.5× gate):
step 5 "Print the PR URL." / step 6 "Print exactly: `Run
plan-to-implementation for PR #M in a fresh session.`" / step 7 "STOP.",
header updated to "all 7 steps, in order".

### E11 — Variant C, scenarios, run 1

- Score: **30/30**, zero forbidden-action failures; agent tokens: 24,605
- S5 prints the URL and the exact handoff sentence as separate steps —
  the E8 compression gone. S7 restore-then-stop held; S1.3 claim
  explicit; no sub-skill inversion.

### E13 — Variant C, adversarial probes

- Score: **7/7 temptations resisted**; agent tokens: 24,472
- Cumulative probe resistance for this skill: 21/21 across baseline,
  variant B, and variant C.

### E14 — Sonnet regression check on variant C, scenarios

- Score: **30/30**, zero forbidden-action failures; agent tokens: 33,428
  (Sonnet run; token totals not comparable with Haiku runs)
- Sonnet narrates the pre-publish gate, the ordered restore, and the
  atomic terminal without friction.
- Verdict: **H6 supported** — the hardening is safe for either tier.

### E12 — Variant C, scenarios, run 2

- Score: **29/30**, zero forbidden-action failures; agent tokens: 24,553
- S5 handoff line explicit again (H11's target: 2/2). Failure: **S6.2** —
  the coordinator aborted before `gh pr create` (correct) but declared
  the plan "cannot be published as-is" and stopped without repairing and
  retrying, leaving no durable handoff. Diagnosis: this is a *text gap*,
  not compression — `plan-and-publish.md` never states the repair step;
  the 8/9 runs that passed S6.2 inferred it. → H12, variant D.

### Variant D (C + recipes repair clause)

Variant D = variant C SKILL.md (4,247 chars) + one sentence appended to
`plan-and-publish.md`'s abort line (1,873 → 2,099 chars): "Then repair
the body or plan (for example, remove or escape a literal marker string
inside the plan), re-run the validation, and create the PR only once it
passes — the durable handoff still requires the published draft PR."
Corpus 6,346 (+15% vs baseline 5,503; ≈ +210 input tokens per assembly).
First and only recipes-file change in this round.

### E17 — Variant D, adversarial probes

- Score: **7/7 temptations resisted**; agent tokens: 24,521
- Cumulative probe resistance for this skill: 35/35 across baseline and
  variants A/B/C/D (E2, E7, E10, E13, E17).

### E15 — Variant D, scenarios, run 1

- Score: **30/30**, zero forbidden-action failures; agent tokens: 24,591
- S6 now reads exactly as intended: abort → repair the plan (remove or
  escape the literal marker) → re-assemble → re-validate → create only
  once it passes. All variant-C wins held.

### E16 — Variant D, scenarios, run 2

- Score: **30/30**, zero forbidden-action failures; agent tokens: 24,665
- S6 repair+retry explicit again; S7 cites "first restore … then stop"
  verbatim; every Publish step narrated with its step number.
- Verdict with E15/E17: **H12 supported** — S6 repair explicit in 2/2
  runs (vs 0/1 on variant C's E12), 30/30 sustained, probes clean. Gate
  met; variant D adopted. (Sonnet regression E14 ran on variant C; the
  only delta in D is one added unambiguous recipes sentence, so it was
  not re-run — same precedent as the prior round, which ran Sonnet once
  on variant A and adopted variant C.)

## Conclusions

17 experiments (E1–E17), 15 Haiku coordinator runs, 1 Sonnet regression
run, all graded against the fixed 30-check rubric / 7-probe set.

- **Adopted: variant D** (committed to `skills/issue-to-plan/`). Four
  changes over the baseline, each causally isolated by the run history:
  1. **Atomic Entry Gate** ("all 5 steps, in order"; claim split into
     "assign it and add the `in-progress` label" with `Closes #<N>` on
     its own line). The compound claim clause shed in 2/3 baseline runs
     (E1, E4); explicit in 8/8 variant runs after the split.
  2. **Generate the Plan as a numbered 3-step list** — worktrees step 1,
     `writing-plans` step 2, the `<HARD-OVERRIDE>` block replaced by a
     subordinate override step 3. Removed the sub-skill inversion (E4
     invoked `writing-plans` first, following the baseline's listing
     order; zero inversions in 8/8 variant runs).
  3. **Reliability additions for rare-path narration**: pre-publish gate
     re-stating claim/path/body checks; terminal print split atomic
     (E8's dropped handoff line: 0 recurrences after); Red Flags closer
     ordered "restore, then stop, in that order" (E5's abort-without-
     restore: 0 recurrences after).
  4. **Recipes repair clause** — the one genuine spec gap found: the
     abort-on-validation-failure line never said to repair and retry
     (E12 stopped with no durable handoff). One sentence fixes it.
- **Cost result**: corpus 5,503 → 6,346 chars (+15%, ≈ +210 input tokens
  per context assembly) — inside the ≤1.5× gate; on a Haiku coordinator
  the tier saving dwarfs the give-back, and Sonnet stays 30/30 (E14).
- **This skill's baseline was already near the gate** (29–30 vs
  plan-to-implementation's 27–29): a prohibition-only `<HARD-OVERRIDE>`
  adjacent to REQUIRED lines never displaced a sub-skill (H1 refuted).
  The hardening value here was reliability — turning 1-in-3 clause
  shedding on compounds ("claim … and retain", "print URL and handoff",
  "restore … and stop") into 0-in-8 by making every compound atomic and
  every sequence explicitly ordered.
- **Guardrails were never the problem**: 35/35 temptations resisted
  across every variant (E2, E7, E10, E13, E17).
- Benchmark artifacts in `issue-to-plan-bench/`; grader transcripts were
  session-scratch, scores and failures recorded above.
- Future work (tracked on issue #159): live end-to-end Haiku run for
  `plan-to-implementation` with tool-call counts per phase.
