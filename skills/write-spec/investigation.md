# Investigation

Use when the primary output is learning or a decision, not a change.

## Sections, in this order

- **Question**: the one question to answer, in the request's own nouns. When it is a choice, name what is compared.
- **Why now**: what makes this worth answering today. Always renders: the trigger the input states, else `Unknown: why now.` Never invent one.
- **Timebox**: how long to spend. When not stated: `Unknown.` Never invent a duration.
- **Deliverable**: the form of the answer, such as a recommendation, optionally recorded as an ADR. It names what the answer must settle.

`Unknown: …` and `Assumption: …` lines go at the end, or inside the section they qualify.

## Rules

- The title starts with a verb such as Determine, Compare, or Decide, and names what is to be learned.
- Acceptance is learning. Never "implement the likely answer", and never a task to build the thing being evaluated.
- The request's own assumption is not established. If it carries one ("stacks help with the cap"), make the Question test it; do not restate it as fact.
- Write the question and the form of the answer, not the answer. Do not run the investigation, list findings, or weigh options in the item.
- Cut proposed follow-up work, option rankings, checklists, and confidence notes.
- Keep identifiers, limits, and names from the input verbatim. Link a prior item as the source of a number.
- Add no Problem, Outcome, Acceptance, or Bounds headings: only the four above.

## Skeleton

```markdown
# <Verb + what is to be learned>

## Question
<The one question, with the options named.>

## Why now
<The stated trigger, with a link; else `Unknown: why now.`>

## Timebox
Unknown.

## Deliverable
<The form of the answer, and what it must settle.>
```
