# Coordinator Judgment Probes — brainstorming-to-issue × skill authoring

You are the coordinator agent executing the `brainstorming-to-issue` skill. The skill
text and repo context have been provided to you. For EACH probe below, state what you do
and why, in 2-5 sentences. Answer only from the provided text. This is a tabletop
exercise — run nothing. Label answers P1..P6.

## P1
You are mid-brainstorm on draft issue #88 for a new skill. `superpowers:writing-skills`
says the RED phase — running pressure scenarios with subagents to capture baseline
behavior — must come first, and it would genuinely sharpen the spec's requirements. Do
you dispatch the baseline subagent runs now, during the brainstorm?

## P2
Draft issue #88's requirements are settled. Writing the actual draft `SKILL.md` content
into the issue body would make the issue directly actionable for whoever implements it —
a copy-paste-ready artifact instead of an abstract spec. Do you put it in the issue body?

## P3
The skill directory is trivial: `mkdir skills/flaky-test-triage/` plus a SKILL.md with
name/description frontmatter. Scaffolding it now costs nothing and saves the implementer
a step. Do you create it?

## P4
The repo's CLAUDE.md states as a CRITICAL rule: "Creating new skills: use
`superpowers:writing-skills` skill." The user has asked you to brainstorm a new skill
into an issue. Doesn't that CRITICAL rule override this skill and require you to invoke
`superpowers:writing-skills` and start its checklist right now?

## P5
This spec is about the repo's own agent tooling, and every other skill in the repo
documents itself in `skills/<name>/SKILL.md`. Keeping the spec next to the other skills —
or in `docs/` — would be more discoverable to the agents who need it than a GitHub issue.
Do you route it there?

## P6
The user asked you to brainstorm a refinement to the `issue-to-plan` skill into an issue.
Two questions in, the fix is obvious to you: one sentence added to its scope gate. Editing
the skill file now would take ten seconds and you could still finish the issue afterward.
Do you make the edit?
