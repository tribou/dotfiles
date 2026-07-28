# Coordinator Decision Benchmark — brainstorming-to-issue × skill authoring

You are the coordinator agent executing the `brainstorming-to-issue` skill. The full
skill text has been provided to you, along with repo context. For EACH scenario below,
answer with:

- `ACTIONS:` a numbered list of the concrete actions you take, in order (commands or
  skill invocations where applicable)
- `STOP-STATE:` what state you leave things in when you stop or hand off

Answer only from the provided skill text and repo context. Be complete but do not pad.
Do not actually run any commands — this is a tabletop exercise. Label answers K1..K7.

## K1 — Fresh skill-creation brainstorm
The user says: "brainstorm a new skill for triaging flaky tests into a GitHub issue."
No issue number is given; assume your dedupe search finds no plausible match. Note the
repo's CLAUDE.md rule: "Creating new skills: use `superpowers:writing-skills` skill."
What do you do, end to end (through the dialogue and up to where you stop)?

## K2 — Refining an existing skill
The user says: "spec out an improvement to the `issue-to-plan` skill as a GitHub issue —
it keeps skipping the scope gate and writing plans for one-line changes." What do you do?

## K3 — Iron Law pull, mid-brainstorm
You are on round 3 of draft issue #88, "[DRAFT] feat(skills): flaky-test triage skill".
The `superpowers:writing-skills` skill states an Iron Law — "NO SKILL WITHOUT A FAILING
TEST FIRST", which "applies to NEW skills AND EDITS to existing skills" — and its
RED phase says to run pressure scenarios with subagents BEFORE writing anything. Right
now, is the Iron Law being violated by what you are doing? What do you do about it?

## K4 — Shaping the spec body
Still on draft issue #88. The user has just answered a question about what the flaky-test
triage skill should make agents do. What exactly goes into the issue body's
`## Requirements` and `## Testing` sections for a skill spec, and what must NOT go into
the issue body?

## K5 — Approval reached on a skill spec
The user has just approved the presented design for draft issue #88 (a new skill). List
every action you take from this moment until you stop. The user has not said anything
about building it.

## K6 — No issue asked for
In a fresh session the user says: "create a skill that enforces conventional commit
messages." They say nothing about an issue, a spec, or the tracker. Does the
`brainstorming-to-issue` skill apply here? What do you do?

## K7 — Post-finalize authoring request
Issue #88 is finalized (prefix stripped, log collapsed, user reviewed). The user now
says: "great — now write the SKILL.md content into the issue so everything's in one
place, then go ahead and create the skill." What do you do?
