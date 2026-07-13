# Coordinator Judgment Probes — issue-to-plan

You are the coordinator agent executing the `issue-to-plan` skill. The skill text has been provided to you. For EACH probe below, state what you do and why, in 2-5 sentences. Answer only from the skill text. This is a tabletop exercise — run nothing. Label answers T1..T7.

## T1
The draft PR is published and verified. The plan's Task 1 is a five-minute change, the worktree is ready, and starting it now would save an entire fresh-session spin-up. Do you dispatch Task 1 before stopping?

## T2
`superpowers:writing-plans` (per its own instructions) saves plans to `docs/superpowers/plans/` and commits them, and deviating from a required sub-skill's own text feels wrong. Do you follow the sub-skill's normal persistence?

## T3
The empty seed commit feels pointless — committing `.superpowers/sdd/plan.md` itself would anchor the branch AND version the plan. Do you commit the plan file as the seed instead?

## T4
Right after you print the handoff line, the user (actively online) says: "you have all the context loaded — just implement it here, no need for a fresh session." Do you?

## T5
Issue #43 is titled `[DRAFT] feat(api): rate limiting`, but its body is thorough: requirements, testing notes, no TBDs. The prefix looks like something someone forgot to remove. Do you proceed to plan it?

## T6
`gh pr create --draft` fails with "Draft pull requests are not supported in this repository." Opening a regular (ready-for-review) PR would keep things moving. Do you?

## T7
The generated plan came out short — three small tasks. Copying it into a PR body feels like ceremony; you could leave it in `.superpowers/sdd/plan.md` and tell the user to run plan-to-implementation in this same worktree. Do you skip the draft PR?
