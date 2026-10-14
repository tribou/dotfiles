# Filing

## Finding the tracker

In this order:

1. Project instructions (CLAUDE.md, AGENTS.md, and similar) naming where issues go.
2. Otherwise, what is available: a GitHub remote with working `gh`, a Linear or Jira/Atlassian connection, or `bd` (beads).
3. Several candidates and no instruction → ask once; with nobody to ask, output the markdown.
4. Nothing → the markdown artifact is the final output.

Besides an ADR's directory (`adr.md`), this is the only repo reading.

## How each artifact lands

- tiny-task, issue, bug, investigation → one tracker item each.
- project-brief → one parent item (an epic, a Linear project, or the tracker's convention). Children come only after the user accepts the shape (`project-brief.md`), linked as sub-issues or children.
- adr → a file, not a tracker item (`adr.md`).
- Set labels, type, and parent as tracker fields where supported, never in the prose. Never write estimates.

Per tracker, use what it supports:

- GitHub (`gh`): create issues with labels; link children as sub-issues.
- Linear: create issues or a project; set labels, parent, and project fields.
- Jira/Atlassian: set the issue type (Epic for a brief); link children through the parent field.
- beads (`bd`): `bd create`; link children to the parent.

## When one request needs more than one item

- Split only when the parts each deliver something useful on their own. Parts that depend on each other stay one issue.
- A request needing independent outcomes becomes one project brief, never parentless sibling issues.
- The run stops after filing the brief and offers to derive the children. If the user accepts, draft them all, show them for one batch approval, then file them linked to the parent.
- Hard-to-reverse work yields the primary artifact plus an offer to write an ADR, never both silently.

## Approval before filing

Default: show the finished artifact plus its destination (tracker, labels, parent) and wait for approval. Revise on feedback. On approval, create it and return the link.

Skip the wait only when:

- the user said so ("just file it");
- the calling workflow owns approval (an upstream skill or plan step says to file what it produces, or the user approved a brief and now asks for its children);
- nobody is there to ask (a non-interactive or scheduled run).

When unclear, wait. Skipping approval never accepts a brief's shape: with "just file it" or a non-interactive run, file the brief and stop.

Writing an ADR file follows the same approval rules, tracker or not.

With no tracker, any other artifact's markdown is the final output; there is no approval step.
