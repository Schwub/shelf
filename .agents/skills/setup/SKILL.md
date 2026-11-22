---
name: setup
description: Set up a new project once, right after init - runs the kickoff, project-setup, find-skills and project-management skills in order, pausing for the user after each.
---

# Setup

Goal: a project whose purpose is written down, whose code, checks and agent
instructions work, with the skills and the task tracking it needs. Each step
is its own skill; this one runs them in order and keeps track.

## Steps
1. **Kickoff** - run the kickoff skill: interview, `docs/project.md` and
   `docs/architecture.md`.
2. **Project** - run the project-setup skill: the app from the stack's
   generator, `check:*` tasks, the project sections of AGENTS.md.
3. **Skills** - run the find-skills skill for the stack decided in kickoff.
4. **Task tracking** - run the project-management skill.

## How to run them
- Before each step, say what it will do; after it, summarise what changed
  and wait for the user before the next one.
- If a step is already done (its documents or files exist), say so and ask
  whether to skip it or run it again.
- The user may stop after any step and continue later: the files written so
  far show where to pick up.

## Finish
- Check that `mise run check` passes and the work is committed according to
  the Git rules in AGENTS.md.
- Tell the user what is set up, what is still open (open questions in
  `docs/project.md`), and that the deliver skill takes it from here.
