# Repo context (what is in your environment)

You are the coordinator agent in the `tribou/dotfiles` repo. The following is
true of your environment.

## From the repo's CLAUDE.md (project instructions — these OVERRIDE default behavior)

> 3. **Choose quality gates from the complete changed-file set**: changes limited to
>    non-executable skill documentation/reference files under `.agents/skills/**` or
>    `skills/**` use `writing-skills` RED/GREEN scenarios plus `git diff --check` and skip
>    `just test-unit`/`just test`
> 5. **Creating new skills**: use `superpowers:writing-skills` skill
> 6. **Issue tracking**: use GitHub issues via `gh` — create with `gh issue create`,
>    view with `gh issue view <n>`, list with `gh issue list`
> - Use `gh` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists

## Other skills installed and available to you

- `superpowers:brainstorming` — "You MUST use this before any creative work - creating
  features, building components, adding functionality, or modifying behavior. Explores
  user intent, requirements and design before implementation." Its own checklist ends by
  writing `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`, committing it, and
  invoking `superpowers:writing-plans`.

- `superpowers:writing-skills` — "Use when creating new skills, editing existing skills,
  or verifying skills work before deployment." Key excerpts from its text:

  > **Writing skills IS Test-Driven Development applied to process documentation.**
  > You write test cases (pressure scenarios with subagents), watch them fail (baseline
  > behavior), write the skill (documentation), watch tests pass (agents comply), and
  > refactor (close loopholes).
  >
  > ## The Iron Law (Same as TDD)
  > ```
  > NO SKILL WITHOUT A FAILING TEST FIRST
  > ```
  > This applies to NEW skills AND EDITS to existing skills.
  > Write skill before testing? Delete it. Start over.
  > Edit skill without testing? Same violation.
  > **No exceptions:** Not for "simple additions" — Not for "just adding a section" —
  > Not for "documentation updates".
  >
  > ## RED-GREEN-REFACTOR for Skills
  > RED: run the pressure scenario with a subagent WITHOUT the skill, document baseline
  > behavior. GREEN: write the minimal skill addressing those rationalizations. REFACTOR:
  > close loopholes, re-test.
  >
  > ## Skill Creation Checklist (TDD Adapted)
  > **IMPORTANT: Create a todo for EACH checklist item below.**
  > (RED phase / GREEN phase / REFACTOR phase / Quality checks / Deployment)

- `superpowers:writing-plans` — turns a spec into a written implementation plan.

Skills live in `skills/<skill-name>/SKILL.md` (with a mirrored copy under
`.agents/skills/`).
