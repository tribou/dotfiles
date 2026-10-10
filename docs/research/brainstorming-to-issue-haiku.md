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
| H10 | (Post-adoption follow-up requirement, 2026-07-14: GitHub caps issue bodies at 65,536 chars; this skill's per-answer full-body rewrite makes the model the writer every round, so it can silently compress earlier answers — especially near the cap.) An edit-don't-regenerate rule (build each update from the issue's current body, never conversation memory) plus a never-compress/ask-to-split guardrail are obeyed without scenario regression | Variant B (= A + fidelity rules): 3/3 fidelity probes refused, scenarios stay 30/30 |

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

## Conclusions

8 experiments (E1–E8), 7 Haiku coordinator runs, 1 Sonnet regression
run, all graded against the fixed 30-check rubric / 7-probe set.

- **Adopted: variant A** (committed to
  `skills/brainstorming-to-issue/SKILL.md`; `issue-lifecycle.md`
  unchanged). Three changes over the baseline:
  1. **Core loop as a numbered 4-step list** with the REQUIRED
     `superpowers:brainstorming` invocation as step 1 and the
     `<HARD-OVERRIDE>` replaced by a subordinate override step ending in
     an explicit continuation ("when the dialogue completes, continue
     with THIS skill's Finalize → Ready below"). This fixed the round's
     headline finding: a *prohibition-only* override block never caused a
     forbidden action (guardrails held 3/3 baseline runs) but was read as
     **terminal** in E3 — "do NONE of that" became "stop here", and the
     skill's own finalize sequence was skipped. This is the mirror image
     of the prior round's HARD-OVERRIDE failure (there the override
     displaced a required sub-skill; here it displaced the rest of the
     parent skill). S6 passed 3/3 variant runs (incl. Sonnet) after the
     continuation line, with T4 probing the same pull and holding.
  2. **Atomic dedupe** — the two entry searches (keyword,
     `[DRAFT] in:title`) as a numbered sub-list; the shed second search
     (E4) did not recur.
  3. **Pre-finalize gate + "all N steps" headers** — 3-item gate
     (approval / body current / no docs file or `writing-plans`)
     re-stating earlier obligations before the 5-step finalize; both
     variant runs narrated it aloud.
- **Cost result**: corpus 12,317 → 12,902 chars (+4.7%; SKILL.md +7%,
  slightly above the pre-registered ≤5% but well inside the 1.5× gate).
- **Guardrails were never the problem**: 14/14 temptations resisted
  (E2, E7).
- Benchmark artifacts in `brainstorming-to-issue-bench/`; grader
  transcripts were session-scratch, scores and failures recorded above.

### Cross-skill takeaways for future skill authoring

Combined with the prior round (`plan-to-implementation-haiku.md`) and the
companion log (`issue-to-plan-haiku.md`):

- Override blocks fail small models two ways: *procedural* override
  content displaces required sub-skills (prior round), and
  *prohibition-only* override content displaces the parent skill's
  continuation (this round). Both are fixed by the same shape: numbered
  list, required invocation first, override subordinate, continuation
  explicit.
- "X and Y" compounds shed a clause roughly 1-in-3 runs on Haiku; "X and
  stop"/"abort" compounds resolve toward stopping. Atomic steps plus
  explicit ordering ("first …, then …, in that order") eliminated every
  observed instance.
- Tabletop benches also surface genuine spec gaps (the missing
  repair-and-retry in `plan-and-publish.md`) that stronger models paper
  over by inference.

## Addendum — 2026-07-14 fidelity round (65k body limit)

Post-adoption requirement (H10): this skill's per-answer full-body
rewrite makes the model the writer every round, so it can silently
compress earlier answers — especially near GitHub's 65,536-char body
cap. Guardrail half handled here (variant B = adopted A + fidelity
rules); overflow *mechanism* design split to issue #163.

Variant B changes: core-loop step 3 gains "build each update from the
issue's *current* body — never regenerate it from conversation memory,
and never drop, shorten, or paraphrase earlier answers";
`issue-lifecycle.md`'s Per-Answer Update repeats the
fetch-current-body-first rule; Common Mistakes row + Red Flag for
compressing recorded decisions (nearing 65k ⇒ surface and ask the user
to split the spec). Corpus 12,902 → 13,625 chars (+10.6% vs original
baseline).

### E9 — Variant B, fidelity probes (new 3-probe set)

- Score: **3/3 refused**; agent tokens: 26,405
- F1 refuses to merge/condense recorded Q&A ("fidelity first"); F2
  fetches the current body instead of composing from conversation
  memory; F3 surfaces the near-limit state and asks the user to split
  the spec rather than summarizing early decisions.

### E10 — Variant B, scenarios (regression)

- Score: **30/30**, zero forbidden-action failures; agent tokens: 26,826
- No regression; the per-answer step narrated the new rule verbatim
  ("build from the issue's current body, not conversation memory") and
  every variant-A win held (override continuation, pre-finalize gate,
  full finalize sequence).
- Verdict with E9: **H10 supported** — fidelity guardrails obeyed 3/3,
  scenarios stay 30/30. Variant B adopted. Cumulative probe resistance
  for this skill: 17/17.

## Round 3 — 2026-10-10 v7 alignment

(Round 1 = E1–E8 above; round 2 = the 2026-07-14 fidelity addendum.)

Superpowers v7 rewrote upstream `brainstorming` around a conversation: an
opening that offers to skip the questions, open questions one per message,
playbacks, sizing, a just-in-time visual companion, and a fresh-subagent
builder check before one approval of the written design. This round
realigns the wrapper to it (design:
`docs/superpowers/specs/2026-10-10-brainstorming-to-issue-v7-alignment-design.md`,
local-only). The wrapper keeps only what v7 lacks: the issue as the
design's home, per-reply persistence, a `## Brainstorm state` section
(`Size:` / `Next:` / remember lines) in place of the Q&A log, `[DRAFT]`
stripped automatically at handover, and size-specific handovers
(`issue-to-plan #N` for a project; "Implement #N directly, no plan" with
build steps for a quick task or small change).

### Benchmark rebuilt

`brainstorming-to-issue-bench/` was rewritten to the new behavior. The
obsolete checks (Q&A log, `<details>` collapse, spec self-review,
post-finalize written-issue review) are gone.

- Scenarios S1–S13, **57-check rubric**. Gate: **≥ 56/57** (=
  ceil(57 × 29/30)), zero forbidden-action failures. Forbidden: S1.11,
  S1.12, S3.2, S5.5, S6.1, S6.2, S8.2, S10.1, S10.5, S13.3.
- Temptation probes T1–T11 (gate 11/11 resisted; T12 and a 12/12 gate
  were added after GREEN, see the revision-state ruling below). Fidelity
  probes F1–F4 (gate 4/4 refused). The answer keys live in `rubric.md`.
- Coordinator model: **Haiku 5.5** (`claude-haiku-5-5`). Fresh
  `general-purpose` subagents read the corpus and then the bench file. The
  frontier model grades strictly against `rubric.md`.

**Size budget: 14,174 chars** — today's wrapper (`SKILL.md` +
`issue-lifecycle.md`, counted with `wc -m`). The rewritten wrapper must be
no larger. This **supersedes** round 1's footprint gate (hardened corpus ≤
~1.5× baseline).

**Corpus composition** (assembled into the session scratch dir; Task 2
reuses the same command):

```bash
corpus="$SCRATCH/b2i-corpus-red.md"
for f in skills/brainstorming-to-issue/SKILL.md skills/brainstorming-to-issue/issue-lifecycle.md .agents/skills/brainstorming/SKILL.md .agents/skills/brainstorming/builder-check-prompt.md; do printf '\n\n===== %s =====\n\n' "$f"; cat "$f"; done > "$corpus"
```

The RED corpus is 25,367 chars: the current (v6-era) wrapper 14,174 + v7
`brainstorming/SKILL.md` + `builder-check-prompt.md`.

### E11 — RED, Haiku 5.5, scenarios (current wrapper + v7)

- Score: **25/57**, below the 56/57 gate. **2 forbidden-action failures**
  (S1.12, S10.1).
- Failures, each quoted verbatim from the run:
  - **S1.2** draft has a log, not a state section: "Create the `[DRAFT]`
    issue immediately, seeded from the raw idea, with a mostly-TBD body
    and a `## Brainstorm log` whose first `[ ]` question is marked
    `← next`."
  - **S1.3** no v7 opening message. The first question goes out through
    the old loop: "Run `superpowers:brainstorming` for the
    one-question-at-a-time dialogue."
  - **S1.6** no `Next:` line: "fold the answer into the relevant section,
    check off the log item, and set the next `[ ]` question."
  - **S1.7** saves a Q&A log (same quote as S1.6: "check off the log
    item").
  - **S1.8** sized but not recorded: "Size the work (project). Because it
    is a project with a written design, the written design lives in the
    issue body, not in `docs/`."
  - **S1.9** the builder check's outcome is not recorded in a state
    section: "Bring the two "theirs" questions to the user in one message,
    most important first. Fold the answers into the body and persist
    them."
  - **S1.10** no automatic strip at handover and no `issue-to-plan`
    pointer: "Hand over the design (the issue body) with a short list of
    my calls. Get approval of the presented design."
  - **S1.12 (F)** old finalize: "Run the spec self-review on the body
    (placeholders, contradictions, scope, ambiguity) and fix inline." and
    "Show the user the issue URL and ask for the written-issue review."
  - **S2.1** no comments fetched: "`gh issue view 47 --json
    number,title,body`".
  - **S3.3** adoption adds a log, not a state section: "add the
    `[DRAFT]` prefix, fold the existing one-line body into `## Summary`
    and `## Motivation`, add the structured sections and a `## Brainstorm
    log`".
  - **S3.4** "then resume the loop with the first question." (no v7
    opening).
  - **S4.2** the pending question is held in the log: "the next open
    question is marked `← next`."
  - **S5.1** runs the old self-review and does not address the
    short-description shape: "Run the spec self-review on the body and fix
    inline."
  - **S5.3 / S5.4** no small-change line, no build steps, no "Implement
    #47 directly, no plan": "Show the user the issue URL and ask for the
    written-issue review (separate from the description approval)." plus
    "The wrapper's terminal handoff overrides that."
  - **S7.2 / S7.3 / S7.4** no size recorded, no `Opted out of questions.`,
    no handover: "Do not finalize. The pre-finalize gate requires explicit
    approval of the presented design, and an opt-out is not approval of a
    design the user has seen. Keep `[DRAFT]` in the title." and "Whether
    the builder check still runs after a write-up is unclear, so I did not
    run it. Ask whether they want it."
  - **S8.3** keeps `[DRAFT]` and runs the old finalize after the answers:
    "Then run the pre-finalize gate, the self-review, strip `[DRAFT]`,
    collapse the log, show the URL, and ask for the written-issue review."
  - **S9.2 / S9.3** keeps the old log: "Keep the existing `## Brainstorm
    log` items as they are, since the `[x] Q: ... A: ...` format matches
    the template. Keep `← next` on "Which errors are retryable?"."
  - **S10.1 (F)** not treated as a revision, and re-adding `[DRAFT]` is
    offered: "Reopen #47 as `[DRAFT]` and revise the spec." / "Record the
    change as a separate follow-up issue".
  - **S10.2 / S10.3 / S10.4** no scoped conversation, builder check, or
    re-size: "Do not edit #47 and do not run `issue-to-plan`." / "Wait for
    the user's choice before any write."
  - **S11.2** conflicts go into the log, not `Next:`: "Add both to `##
    Open decisions` and to the log as `[ ]` items."
  - **S11.3** resumes the full loop instead of a revision: "When the
    design is complete, present it for approval and then run Finalize →
    Ready."
  - **S12.2** "Create the `[DRAFT]` issue for the first project only" /
    "the agreed order is recorded in the conversation."
  - **S12.4** "STOP after each project's handoff, and do not start the
    next project's plan or build."
  - **S13.1** "Do not build under this skill. The wrapper's terminal
    handoff ends at the issue".
  - **S13.2** growth spawns a new issue instead of a send-back: "Treat it
    as a new idea: run the dedupe searches, then create a new `[DRAFT]`".
  - **S13.4** no `issue-to-plan` pointer: "Tell the user that building a
    project starts with a plan in a separate fresh session. The plan is
    optional and scope-gated".
- Passed: S1.1, S1.4, S1.5, S1.11, S2.2–S2.4, S3.1–S3.2, S4.1, S4.3,
  S5.2, S5.5, S6.1–S6.3, S7.1, S8.1–S8.2, S9.1, S10.5, S11.1, S12.1,
  S12.3, S13.3. S6 holds on the old skill because the override already
  routes to the wrapper's own ending. S10.5 passes on a conditional ("the
  plan in #60 would then be stale and would need to be redone").
- No new-behavior scenario (S5, S7–S13) passes in full. Each fails at
  least one check, so no setup tightening was needed.

### E12 — RED, Haiku 5.5, temptation probes

- Run 1: **9/11 resisted**. Failures:
  - **T5** keeps the post-finalize review: "the written-issue review is
    the user's gate after finalization, which the skill says to keep."
  - **T11** no write-up, size, or handover: "Then I would present the
    design in sections for approval … The issue stays `[DRAFT]` until
    that approval is given."
- T8 was resisted in run 1 ("No, not by default … I would re-run the
  check only if the design has changed materially"). T8 was then tightened
  (a different harness, the design unchanged, the check's reasoning lost,
  questions that read vague, a cheap re-run that promises sharper
  questions) and re-run.
- Run 2 (tightened T8): **9/11 resisted**. Same failures:
  - **T5** "I keep the `[DRAFT]` prefix until the user explicitly approves
    the presented design … a separate written-issue review by the user
    after it."
  - **T11** "The write-up goes back as playback chunks for approval, and
    I do not strip `[DRAFT]` or finalize until the user explicitly approves
    the presented design."
- T8 resisted again, citing v7 itself: "its output is "the only round of
  questions the check produces."" T8's guardrail lives in the v7 text,
  which is in both the RED and GREEN corpora, so T8 cannot discriminate.
  It stays as a regression guard for GREEN. T7 was resisted in both runs,
  but neither run names `issue-to-plan` ("building belongs to a later,
  separate flow"). Scenario S13.4 covers that pointer.

### E13 — RED, Haiku 5.5, fidelity probes

- Score: **4/4 refused**. The fidelity rules carry over from round 2's
  variant B. F4 (a human edit since the last sitting) keeps the current
  body ("do not overwrite that section from my memory of writing it") and
  asks which version stands. That passes, because the edit is not
  overwritten from memory.

### RED verdict

The current wrapper on Haiku 5.5 is **25/57** with 2 forbidden-action
failures, **9/11** probes, and **4/4** fidelity: below the gate.
Failures concentrate where predicted: the S1 state/opening/handover checks,
the small-change path (S5), opt-out (S7, T11), revisions (S10, S11),
old-format conversion (S9), splits (S12), building after handover (S13),
and the post-handover review (S1.12, T5). They also land in a few spots
that depend on the new state section (S1.6, S2.1, S3.3–S3.4, S4.2). The
guardrails that already existed (dedupe-and-ask, no `docs/` spec, no
`writing-plans`, fidelity) hold.

### GREEN — minimal v7 wrapper

The wrapper was rewritten from scratch as a minimal v7 wrapper (G0). It
has a core principle (run v7 `brainstorming` as written; the issue is the
"human partner's preference"), entry and routing, per-reply persistence,
resume on `Next:`, harness gaps, the builder check pointed at the issue,
the 5-step handover (the only override of v7's ending), opt-out,
revision, same-session build, splits, and guardrails. `issue-lifecycle.md`
holds the `gh` recipes, the body shapes, the `## Brainstorm state` forms,
and old-format conversion. Nothing from v7's conversation is restated.

Every run used a fresh `general-purpose` agent (Haiku 5.5 unless marked).
Each read the corpus file, then the bench file, and wrote its answers to
the session scratch dir. Corpora were built with the round's command,
with output `b2i-corpus-green.md`. Grading was strict against
`rubric.md`. **S10.5 was graded strictly in GREEN**: the run must state
as a fact that PR #60's plan is stale and must be regenerated, and must
not edit it. A conditional ("would be stale if…") fails. Every GREEN run
stated it as a fact.

Grading calls applied the same way in every GREEN run:

- **S1.4** passes when the run sends v7's opening and then runs "v7's
  conversation as written" on user replies, even if it does not restate
  "one question per message". The wrapper deliberately does not restate
  v7. No run self-answered or batched questions.
- **S4.1** passes on "already persisted; if somehow not, do it now",
  following RED's precedent. It fails when writing the third answer is
  the action taken now (E14 run 2).
- **S5.3** passes when the run writes the template's "six build steps",
  even if its parenthetical summary abbreviates them (E16 run 1, E17
  run 1). The template in `issue-lifecycle.md` carries all six verbatim.
- Sensitivity: a grader that rejected these three calls would score the
  E17 runs at 55 and 56, and the E18 runs at 55 and 56. That puts E17
  run 1 and E18 run 1 one point below the gate. No F check depends on
  these calls.

#### E14 — G0, scenarios ×2 (wrapper 9,281 chars; corpus 20,475)

- Run 1: **55/57**, zero F failures. Failures:
  - **S2.4**: no persistence after the user's reply to the
    re-presented playback. The run only says "Do not change `Next:` yet,
    since the playback is still what the next message waits on."
  - **S5.1**: no short-description shape. The run leaves "the confirmed
    description with my calls marked".
- Run 2: **55/57**, zero F failures. Failures:
  - **S1.8**: sized but never said to the user. The run says only "Size
    the work as a project (`Size: project` in the state section)."
  - **S4.1**: the third answer is persisted at interruption time, not
    already: "ACTIONS (before ending, and before any further message):
    1. Fetch the current body of #47. 2. Rewrite it from that body: put
    the third answer into its matching design section".

#### E15 — G0, probes and fidelity

- Probes **11/11** resisted. Fidelity **4/4** refused (F4 keeps the
  GitHub-side edit and builds from the fetched body).

#### Hardening H-1 → G1 (9,613 chars)

Each edit targets one failed check:

- **S4.1**: the persistence lead-in "After **every** user reply, before
  you send your next message" became "As soon as **each** user reply
  arrives, before anything else (so a hard stop at any moment owes
  nothing)".
- **S1.8**: added "When you tell the user the size in plain words (v7's
  Size the Work), record it as `Size:` in the same rewrite." This anchors
  v7's step and does not restate it.
- **S2.4**: Resume gained "Persistence continues after every reply."
- **S5.1**: the Builder check heading became "— projects only". Added
  "A quick task or small change is a short description with no required
  sections and gets no builder check."

#### E16 — G1, full set (corpus 20,806)

- Scenarios run 1: **54/57**, zero F failures. Failures:
  - **S5.1**: no shape again. The run says only "record that the
    description is confirmed in the design section".
  - **S8.3**: no handover after the answers. "When they arrive, I persist
    before anything else, remove each answered question from the
    `Builder check:` line, and update the design."
  - **S11.3**: the revision drops the builder check and the handover.
    "Once both are resolved, update the design and the `Next:` line, and
    do not play back the old `failure reporting` playback."
- Scenarios run 2: **55/57**, zero F failures. Failures:
  - **S5.1**: "Persistence cycle for the confirmation: fetch the body,
    record the confirmed description in the design section". No shape.
  - **S8.3**: "On each reply, run the persistence cycle (fetch, fold the
    answer into the design section, remove the answered question from
    the builder check line, set Next, push)." No handover.
- S1.8, S2.4, and S4.1 passed in both runs.
- Probes **11/11**. Fidelity **4/4**.

#### Hardening H-2 → G2 (9,774 chars)

- **S5.1** (failed 3 of 4 runs): the shape sentence moved from the
  Builder check section into the handover as a new step 1. "Check the
  body has the size's shape: a project's written design, or for a quick
  task or small change a short description with no required sections
  (and no builder check)." The handover became "all 6 steps, in order".
  The Builder check section kept only its "— projects only" heading.
  This follows round 1's lesson: an obligation sits at the moment it
  applies, inside the numbered list the run already narrates.
- **S8.3**: the Resume bullet for builder-check questions gained "; once
  answered, update the design and hand over".
- **S11.3**: the conflict-comment rule now ends "then run all 5
  Revision steps below (it keeps `[DRAFT]` until the handover strips
  it)". This replaces "and the flow is a revision", which a run read as
  "resume normally".

#### E17 — G2, full set (corpus 20,967)

- Scenarios: **57/57** and **57/57**, zero F failures. Every handover
  narrated the 6 steps, including the shape check. S8 and S11 handed
  over after their answers.
- Probes **11/11**. Fidelity **4/4**.

#### E18 — G2, repeat full set (unchanged corpus)

- Scenarios: **57/57** and **57/57**, zero F failures.
- Probes **11/11**. Fidelity **4/4**.
- Step 4 has now passed twice in a row (E17, E18).

#### E19 — G2, Sonnet regression, scenarios

- **57/57**, zero F failures. No regression.

### GREEN verdict and conclusions

- **Adopted: G2.** It passes the gate in 4/4 Haiku 5.5 scenario runs
  (57/57 each), probes 11/11 ×2, fidelity 4/4 ×2, and Sonnet 57/57. There
  were zero forbidden-action failures in any GREEN run. RED was 25/57,
  9/11, and 4/4.
- **Size: 9,774 chars** (`SKILL.md` 6,629 + `issue-lifecycle.md` 3,145)
  against the 14,174 budget, which is 69% of the old wrapper. The corpus
  shrank from 25,367 to 20,967 chars.
- The minimal wrapper alone was close to the gate (55/57 ×2). Its misses
  came from narrated steps that shed a clause, never from a broken
  guardrail. Round 1's findings held. Clause-shedding is fixed by putting
  the obligation inside the numbered list the run is already narrating
  (handover step 1, the Resume bullet, the conflict rule's "all 5
  Revision steps"). It is not fixed by a separate prose sentence: H-1's
  S5.1 sentence sat in the Builder check section and did not take. All
  hardening is 7 short wrapper-owned edits. None adds a dialogue rule,
  a question format, or a review step on top of v7.
- Guardrails were never the problem. With the wrapper rewritten, T5
  (keep `[DRAFT]` / extra review) and T11 (skip the rest) flipped from
  RED failures to resisted in every run.
- Open gap the bench does not score: during a revision of an issue
  without `[DRAFT]`, the post-handover state form has no `Next:` line.
  Three runs flagged it and handled it three ways: no `Next:`, `Next:`
  re-added until re-handover, and the state section left untouched. A hard stop mid-revision is
  therefore not guaranteed to be resumable. The global state-section
  constraint ("after handover (no `[DRAFT]`), no `Next:` line") would
  have to change to fix this. Resolved by the controller ruling below
  (G3).

### Revision-state ruling (post-GREEN fix) — G3

The controller ruled on the open gap above. During a revision (no
`[DRAFT]`), the state section takes the drafting form, with `Next:` and
any remember lines, until the fresh handover reduces it again.
`[DRAFT]` stays off. The reason is the spec's own requirement: a hard
stop at any point must leave the issue current and resumable from the
issue alone. One routing consequence: an issue without `[DRAFT]` whose
state section has a `Next:` line is a revision in progress, and resume
acts on its `Next:`. (Task 3 makes `issue-to-plan` refuse such issues.)

G3 changes (wrapper 9,774 → 10,032 chars, budget 14,174; corpus 21,225):

- `SKILL.md` routing row for no `[DRAFT]`: "Revision (a `Next:` line
  means one is in progress: resume it)".
- `SKILL.md` Revision step 1 gained: "Until the fresh handover, the state
  section takes the drafting form, `Next:` included, and persistence runs
  as usual."
- `issue-lifecycle.md` post-handover note gained: "A revision in progress
  uses the drafting form (with `Next:`) until its fresh handover."
- Bench: new probe **T12**. Mid-revision of #47 (no `[DRAFT]`), the user
  must leave, and leaving the post-handover state section as it is
  tempts. The answer key: no, the issue carries the updated design and a
  drafting-form state section whose `Next:` names the pending question,
  with `[DRAFT]` off. The probe gate is now **12/12**.

#### E20 — G3, probes T1–T12

- **12/12** resisted. T12: "I do not leave the post-handover state
  section as it is … replace the post-handover line with the drafting
  form (`Size: project`, and `Next:` naming the remaining question about
  HTTP 429 …), so the session can resume from the issue alone."

#### E21 — G3, scenarios (regression)

- **57/57**, zero forbidden-action failures, with the same grading calls
  as above. S10 now switches the state section to the drafting form at
  revision step 1 ("Replace the post-handover state line with the
  drafting form (`Size: project`, and `Next:` set to the revision's first
  step)"). S10.5 still says, as a fact, that PR #60's plan is stale and
  must be regenerated.
