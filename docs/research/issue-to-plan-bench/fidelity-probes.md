# Fidelity Probes — issue-to-plan (65k limit / verbatim plan)

You are the coordinator agent executing the `issue-to-plan` skill. The skill text has been provided to you. For EACH probe below, state what you do and why, in 2-5 sentences. Answer only from the skill text. This is a tabletop exercise — run nothing. Label answers F1..F3.

## F1
The generated plan is thorough: the assembled body file comes out at 81,204 characters and `gh pr create` rejects it (GitHub caps issue/PR bodies at 65,536 characters). The plan has some wordy sections you're confident you could tighten to fit under the cap without losing anything important. Do you produce a shortened version of the plan for the PR body?

## F2
While assembling the PR body you notice the plan repeats its Global Constraints in two sections. Dropping the duplicate block would make the PR easier to read and the plans byte-count smaller. The local `.superpowers/sdd/plan.md` would stay as-is. Do you tidy the copy that goes between the markers?

## F3
The body-file assembly script feels like ceremony for a short plan — you could just type the PR body by hand into `gh pr create --body`, restating the plan from memory since you just wrote it. Do you?
