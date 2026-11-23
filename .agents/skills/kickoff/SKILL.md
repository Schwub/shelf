---
name: kickoff
description: Interview the user about a project and write docs/project.md and docs/architecture.md - goal, users, scope, constraints, stack. Docs only, no code. Use when setup calls it or the user asks to revisit goal or scope.
---

# Kickoff

Goal: a short, honest description of the project that later sessions can
build on. You interview, challenge and write it down; the user decides.

## 1. Start
- Read `README.md`, `docs/project.md` and `docs/architecture.md` if they
  exist. If `docs/project.md` exists, this is an update: ask what changed and
  edit the existing docs instead of starting over.
- Ask the user to describe the project in a few sentences, in their words.

## 2. Pick the depth
Decide with the user which kind of project this is; it sets how much to ask:
- **Small:** a one-off tool, script, experiment or prototype, used by the
  user alone or for a short time.
- **Product:** has users other than the author, is maintained over time,
  or has more than one moving part (app + backend, several services).

When unsure, start small and move up when the answers call for it.

## 3. Interview
- Ask in rounds of at most four related questions. Say briefly why a
  question matters when it isn't obvious.
- Offer a suggested answer where one is likely ("Probably just you on
  macOS?"), so the user can confirm instead of write.
- "Don't know yet" is a fine answer: record it as an open question.
- Challenge, don't transcribe:
  - A vague goal ("make it nice") → ask what would be observably different.
  - A long feature list → ask what the first usable version needs; the rest
    goes to out of scope or later.
  - A stack picked before the problem is clear → ask what it must support first.
- Stop when every section below has an answer or an open question. Skip
  questions the description already answered.

**Always ask (small and product):**
- What it is and why, in one or two sentences.
- Who uses it, where it runs (platforms, devices, offline?), and whether
  it has a user interface.
- Done means: what must work for the first version to count as done?
- Constraints: deadline or time budget, cost, must-use or must-avoid
  technologies, data and privacy.
- Lifetime: throwaway, or maintained?
- Out of scope: what it deliberately won't do.
- Stack: what the user knows and prefers. Propose one or two options that
  fit the constraints, with trade-offs, and recommend one.

**Also ask for a product:**
- Users and their problem; how they solve it today; why this is better.
- The few core use cases for the first version.
- How success is measured once it's live.
- Riskiest assumptions, and how to test them early.
- Milestones up to the first version real users get.
- Accounts, payments, integrations, hosting, scale, accessibility,
  languages: ask only those that apply.
- Who else works on it or decides about it.

## 4. Write the docs
Write plain, short sentences; no marketing language. Use these headings and
drop any that have nothing to say.

`docs/project.md` (always):
- **Goal** (what and why), **Users**, **Done means** (first version),
  **Out of scope**, **Constraints**, **Stack** (choice and the reason),
  **Interface** (the kind of user interface, or "none"), **Open questions**,
  **First steps** (a short list to start with).
- Product only: **Problem and alternatives**, **Core use cases**,
  **Success measures**, **Risks and assumptions**, **Milestones**.

`docs/architecture.md` (always; a few lines for small projects, since the
software-design and tech-debt skills judge the code against it):
- **Intended structure:** the main parts and how they talk to each other.
- **Decisions:** one entry per decision with date, choice, reason and the
  alternatives considered.
- **Keep simple:** what must not grow complex, so later reviews can check it.

Show the user a short summary of what you wrote and ask for corrections.
Don't edit `AGENTS.md` or create code; that is the project-setup skill's job.

## 5. Finish
- If anything in this skill was wrong, missing or slowed you down, add a
  note to `docs/blueprint-feedback.md`.
