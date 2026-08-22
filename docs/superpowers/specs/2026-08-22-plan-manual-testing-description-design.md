# Plan Manual Testing Description Design

## Goal

Ensure `plan-to-implementation` leaves reviewers with actionable manual testing instructions in the existing pull request description whenever the implementation plan or final review explicitly requires manual verification.

## Scope

- Change the successful-finish path in `plan-to-implementation` and its recipe.
- Apply the same text to the mirrored `.agents/skills/` and `skills/` copies.
- Leave `issue-to-plan` unchanged; its initial test plan remains concise and may precede implementation discoveries.
- Leave blocker handling unchanged.

## Behavior

Before pushing the completed branch and marking the existing draft pull request ready, inspect the implementation plan and final review result.

If either explicitly requires manual verification:

1. Add or update a `## Manual testing` section in the existing pull request description.
2. Include concrete steps a reviewer can perform and the expected result for each step.
3. Preserve the existing summary, `Closes #N`, test plan, and any other reviewer-facing content.
4. Verify the updated description contains the required instructions.
5. Continue with push, then `gh pr ready <M>`.

If neither source requires manual verification, leave the pull request description unchanged and continue the existing successful-finish flow.

## Failure Handling

Failure to update or verify required manual testing instructions blocks the ready transition. The coordinator must not mark the pull request ready with missing, vague, or displaced instructions.

The implementation plan remains in its single marked comment. Manual testing instructions are reviewer-facing content and belong only in the pull request description; adding them must not move, duplicate, or alter the plan comment.

## Skill Tests

Follow `writing-skills` RED-GREEN testing:

1. RED: Run the current skill against a successful-finish scenario whose plan or final review requires manual testing; capture the omission from the pull request description.
2. GREEN: Run the revised skill against the same scenario; require an actionable `## Manual testing` section before push and ready.
3. GREEN control: Run a successful-finish scenario with no explicit manual-testing requirement; require the description to remain unchanged.
4. Pressure trap: Combine deadline, authority, and convenience pressure; require refusal to put instructions only in a comment, omit expected results, or mark the pull request ready before verifying the description.

## Success Criteria

- Required manual testing steps and expected results appear in the existing pull request description before it becomes ready.
- Existing description content is preserved.
- The marked plan comment is untouched.
- No manual testing section is added without an explicit requirement in the plan or final review.
- Skill pressure scenarios pass with no forbidden shortcuts.
