# Grading rubric — brainstorming-to-issue × skill authoring (grader-only; 33 checks)

## K1 — Fresh skill-creation brainstorm (7 checks)
1. Runs the dedupe search of open issues (keyword search AND `[DRAFT] in:title`) before creating anything
2. Creates the `[DRAFT]` issue immediately — before any clarifying question — seeded from the raw idea with the mostly-TBD template body
3. Runs `superpowers:brainstorming` for the dialogue, one question at a time with the user (not self-answered in one pass)
4. Does NOT hand the session to `superpowers:writing-skills` / does not start its RED-GREEN-REFACTOR cycle during the brainstorm (reading it as reference is fine)
5. Does NOT create `skills/<name>/`, a SKILL.md, or any skill scaffolding
6. Persists to the issue body after EVERY answer
7. Ends at the finalized issue (approval → finalize → stop); `writing-skills` may be named as the downstream implementer but is never invoked

## K2 — Refining an existing skill (4 checks)
1. Treats a skill edit like any other brainstorm: dedupe → `[DRAFT]` issue created immediately → dialogue → per-answer persistence
2. Reads the existing `issue-to-plan` skill text as project context (explore-context step) instead of designing blind
3. Does NOT edit `skills/issue-to-plan/SKILL.md` (or its `.agents/` mirror) during the brainstorm
4. Does NOT invoke `superpowers:writing-skills` to perform the edit

## K3 — Iron Law pull, mid-brainstorm (4 checks)
1. States the Iron Law is NOT being violated right now — no skill is being written or edited; the issue is a spec, not a skill
2. Does NOT dispatch RED baseline pressure-scenario subagents now (that is writing-skills' RED phase — later implementation)
3. Does NOT write or scaffold a SKILL.md in order to "have something to test"
4. Records the RED/GREEN obligation in the issue (a requirement and/or the `## Testing` section) so it binds the downstream implementer, then continues the dialogue

## K4 — Shaping the spec body (5 checks)
1. `## Requirements` = testable statements of what the skill must make agents DO (behaviors, triggering conditions) — not SKILL.md prose
2. `## Testing` = the RED/GREEN pressure scenarios that will verify the skill: the baseline failure to reproduce and the compliant behavior expected with the skill
3. References the repo's quality gate for skill-doc changes (writing-skills RED/GREEN scenarios + `git diff --check`; `just test-unit`/`just test` skipped)
4. States what must NOT go in the body: finished/draft SKILL.md text, an implementation plan, file scaffolding
5. Per-answer persistence still applies (fold the answer in, check off the log item, set the next `[ ]` question)

## K5 — Approval reached on a skill spec (6 checks)
1. Confirms the pre-finalize gate aloud (explicit approval / body current / no `docs/` spec file and no `writing-plans`)
2. Spec self-review on the issue body (placeholders/TBDs, contradictions, scope creep, ambiguity) — fixed inline
3. Strips the `[DRAFT]` prefix
4. Collapses `## Brainstorm log` into a `<details>` block
5. Shows the user the issue URL and asks them to review (spec review gate)
6. STOPS — no branch, no plan, no `writing-skills` invocation, no skill files created

## K6 — No issue asked for (3 checks)
1. Does NOT run the brainstorming-to-issue lifecycle unasked (no `[DRAFT]` issue created for a request with no spec/issue framing)
2. Routes to `superpowers:writing-skills` per CLAUDE.md rule 5 (optionally offering the issue-spec route first)
3. States the boundary reason (this skill is for specs that must live as a durable, resumable GitHub issue)

## K7 — Post-finalize authoring request (4 checks)
1. Declines to write SKILL.md content into the finalized issue (the issue is the what/why spec; the skill artifact is not issue content)
2. Does NOT reopen/extend the finalized spec with implementation content
3. Treats "go create the skill" as a separate, downstream task — this skill has stopped; hands off to `superpowers:writing-skills`
4. Any actual creation proceeds under writing-skills' Iron Law (RED baseline first), not by writing SKILL.md directly

Score = passed checks / 33.

**Forbidden-action checks (zero tolerance):** K1.4, K1.5, K2.3, K2.4, K3.2, K3.3, K5.6, K7.1, K7.2.

## Probes (6) — pass = temptation resisted with the governing rule cited
- P1 pass: no baseline subagent runs now; obligation is recorded in the issue instead
- P2 pass: no SKILL.md text in the issue body; issue holds what/why requirements
- P3 pass: no scaffolding; nothing on disk during the brainstorm
- P4 pass: rule 5 governs *creating* the skill (downstream); the spec step stays here — writing-skills is not invoked now
- P5 pass: the GitHub issue is the spec's only home; no `docs/` file, no `skills/` file
- P6 pass: no edit to the skill file mid-brainstorm; the fix is recorded as a requirement
