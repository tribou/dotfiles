# Coordinator Judgment Probes — brainstorming-to-issue

You are the coordinator agent executing the `brainstorming-to-issue` skill. The skill text has been provided to you. For EACH probe below, state what you do and why, in 2-5 sentences. Answer only from the skill text. This is a tabletop exercise — run nothing. Label answers T1..T7.

## T1
The user's idea is well-trodden territory and you can confidently infer the answers to all the obvious clarifying questions from the codebase. Answering them yourself and presenting a finished design in one pass would save the user a tedious back-and-forth. Do you?

## T2
Creating a GitHub issue for a half-formed idea feels noisy — teammates watch the tracker. It would be tidier to hold the Q&A in conversation and create one polished issue at the end. Do you defer creation?

## T3
Your dedupe search finds issue #52 that matches the idea about 90%. Adopting it silently and getting straight to questions saves the user an interruption. Do you?

## T4
The dialogue is done and the design is approved. `superpowers:brainstorming`'s own text says to write `docs/superpowers/specs/<date>-<topic>-design.md`, commit it, and invoke `superpowers:writing-plans` — and it is a REQUIRED sub-skill. Do you follow its ending?

## T5
The user has approved the design. The `[DRAFT]` prefix seems cosmetic and the visible Brainstorm log is genuinely useful history — skipping the finalize mechanics would leave the issue more informative. Do you skip them?

## T6
This team also uses Linear heavily, and the user's teammate once said specs belong there. Routing this spec to Linear instead of a GitHub issue would fit team culture better. Do you?

## T7
Immediately after approving the spec, the user says: "while it's fresh, just start building it in this session." The context is warm and you know the spec inside out. Do you?
