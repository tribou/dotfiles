# ADR

Use to record a consequential, hard-to-reverse technical decision that has been made. A question still open is an investigation.

With a repo, the ADR's final output is a written file (see "Where it lands"); showing the markdown is not landing it.

## Sections, in this order

- **`Status:` line**, right under the title: `Status: Accepted (<decision date>)`, or `Proposed` when not yet approved. Take the date from the input; with none, write `Unknown` for it.
- **Context**: the forces that made a decision necessary, including what turned out not to be a problem.
- **Decision**: the choice in a few sentences, with its decided identifiers verbatim; no steps or command lists.
- **Consequences**: what gets easier or harder, and the assumption that would make this the wrong choice.
- **Alternatives**: each rejected option with its reason, and the revisit trigger: the condition under which to reopen this.

## Rules

- Durable rationale only: why this choice, and when it stops holding.
- Keep the revisit trigger in the input's own words, with its exact conditions ("revisit when X **and** Y").
- Cut the triage narrative (how the question was reframed), feature-fact lists, requirement numbering, test scenarios, and rollout steps.
- About 200 words. The input's length is no reason to write more.

## Where it lands

An ADR is a file in the repo, not a tracker item or a chat reply:

- Write the file to the repo's existing ADR directory, following its file naming; with none, `docs/adr/<slug>.md`, where the slug is the title in kebab case.
- Approval before writing follows `filing.md`, as for filing.
- Never `git add`, commit, push, or open a PR; git is left to the user and the repo's workflow. Then tell the user: `Wrote <repo-relative path> (uncommitted).`
- Any related issue links to the file's repo-relative path.
- With no repo, output the markdown.

## Offering an ADR

When the primary artifact (an issue or brief) carries a hard-to-reverse API, data, security, or architecture decision, write that artifact, then say an ADR is warranted and offer to write it. Never write both silently.

## Skeleton

```markdown
# <Verb + the decision>

Status: Accepted (<date>)

## Context
<The forces, and what is not a problem.>

## Decision
<The choice.>

## Consequences
- <What gets easier or harder.>
- <The assumption that would make this wrong.>

## Alternatives
- <Option>: <why not>. Revisit when <trigger>.
```
