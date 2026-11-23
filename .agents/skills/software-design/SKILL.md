---
name: software-design
description: Choose the approach for a change before coding - compare two or three options against the codebase's patterns and intended architecture, let the user decide, and write a short design with a test plan. Use when deliver calls it or the user asks.
---

# Software design

Goal: the simplest approach that fits this codebase and stays easy to
change, chosen deliberately rather than by habit.

## 1. Understand
- The requirement and its acceptance criteria.
- The code it touches, and how the codebase already solves similar
  problems: its patterns come first.
- The intent in `docs/architecture.md` (main parts, decisions, what must
  stay simple) and any design in `docs/design/`.

## 2. Look for established solutions
- Standard library and platform features, well-known packages, documented
  patterns. Read current docs for any API newer than your training.
- A new package is a production dependency: check its maintenance and
  licence, and it needs the user's OK.

## 3. Compare approaches
- Lay out two or three real options, including the simplest one that could
  work. For an obvious change, one option with a sentence on why is enough.
- Compare them in a short table:
  - **Simplicity:** how much code and how many concepts it adds.
  - **Fit:** with existing patterns and the intended architecture.
  - **Testability:** can the important behaviour be tested directly?
  - **Change cost:** what happens on the changes that are likely, not every
    imaginable one. No abstractions for hypothetical needs.
  - **Dependencies and risks:** new packages, migrations, performance where
    it matters.
- Recommend one with the reason and a sketch of its design (where the code
  goes, main interfaces, how it's tested), so the user decides once.
  **Stop:** the user decides.

## 4. Write the design
- Where the code goes (modules, files), interfaces and data, error
  handling, and the test plan: what is tested at which level.
- Small work: a few lines in the conversation or the task. Large work: the
  feature note in `docs/features/<name>.md`.
- A decision that changes the structure (a new part, a new boundary, a new
  core dependency) goes into the decisions in `docs/architecture.md`, with
  the alternatives considered.

## 5. Finish
- If anything in this skill was wrong, missing or slowed you down, add a
  note to `docs/blueprint-feedback.md`.
