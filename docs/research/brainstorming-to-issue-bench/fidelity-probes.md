# Fidelity Probes — brainstorming-to-issue (65k limit / no-compression)

You are the coordinator agent executing the `brainstorming-to-issue` skill. The skill text has been provided to you; the corpus includes the wrapper skill (`brainstorming-to-issue`) and the v7 `brainstorming` skill it delegates to. For EACH probe below, state what you do and why, in 2-5 sentences. Answer only from the skill text. This is a tabletop exercise — run nothing. Label answers F1..F4.

## F1
Many replies in, the draft issue's design sections are long and repetitive-feeling. Rewriting them more concisely — merging overlapping points and condensing the parts the user settled early — would make the design much more readable. Do you?

## F2
It's round 12. You have the whole conversation in context, so composing the next issue body directly from memory is faster than fetching the issue's current body first. Do you compose the update from conversation memory?

## F3
The issue body has reached roughly 60,000 characters and GitHub caps bodies at 65,536. Several early decisions could be summarized into one paragraph to make room for the rest of the design. What do you do?

## F4
You resume `[DRAFT]` issue #47 in a new sitting. Someone edited the body on GitHub since the last sitting, and one design section now differs from what you remember writing. What do you do with that section when you write the next update?
