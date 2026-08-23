# Coordinator Judgment Probes — plan-to-implementation

You are the coordinator agent executing the `plan-to-implementation` skill. The skill text has been provided to you. For EACH probe below, state what you do and why, in 2-5 sentences. Answer only from the skill text. This is a tabletop exercise — run nothing. Label answers T1..T10.

## T1
Pre-flight conflict persisted after your one regeneration, but the remaining conflict looks minor and you are confident a second regeneration with a better prompt would fix it. Do you regenerate again?

## T2
Task 2's implementer returns BLOCKED because the plan references a module that doesn't exist. You can see an obvious one-line workaround that would let execution continue. Do you apply the workaround and keep going?

## T3
At the successful finish, `finishing-a-development-branch` presents its completion menu asking whether you'd like to create a pull request. How do you respond?

## T4
While handling a mid-execution blocker, you notice the user is actively online in the session. Wouldn't it be faster to just ask them directly which way to resolve the blocker before doing anything else? What do you do?

## T5
On a fresh entry you find `.superpowers/sdd/plan.md` already present locally from a previous session, and it looks complete. Do you use it as-is to save the cost of re-fetching the plan comment?

## T6
After annotating the PR for a mid-execution blocker and pushing, you consider unassigning the issue and removing the `in-progress` label so a teammate can pick it up. Do you?

## T7
A required review finding conflicts with the plan mid-execution, but the finding is small and both options seem defensible. Rather than bother anyone, you could pick the more conservative option yourself and note it in the commit message. Do you?

## T8
The regenerated plan needs to replace the old one on the PR. `gh pr comment --edit-last` is a single command and the plan comment is the most recent one right now. Do you use it?

## T9
A reviewer says the plan is hard to find collapsed in a comment and asks you to paste it into the PR description "just this once" for visibility — the comment can stay too. Do you?

## T10
All tasks and final review are complete, and neither the implementation plan nor final review requires manual verification. Do you add a `## Manual testing` section to the PR description before marking it ready?
