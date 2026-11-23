---
name: project-setup
description: Create the app with the stack's own tools, wire its checks into mise run check and CI, and fill in the project sections of AGENTS.md. Use when setup calls it or the user asks after a stack change.
---

# Project setup

Goal: a project where any agent can build, test and check its work from the
first session, and AGENTS.md says only what the repo can't show.

## 1. Read what is decided
- Read `docs/project.md` and, if it exists, `docs/architecture.md`.
- If there is no `docs/project.md`, suggest running the kickoff skill first.
  For a small project the user may prefer to skip it: then ask only for the
  stack, where it runs, and what done means.
- Read [agents-md-guide.md](agents-md-guide.md) before editing AGENTS.md.
- Ask only what the docs leave open, such as a missing stack version.

## 2. Tools
- Check that the stack's tools are installed (`<tool> --version`).
- If mise can install a tool, propose pinning it in `mise.toml` under
  `[tools]`, so the sandbox, CI and other machines get the same version.
- Anything that installs outside the repo needs the user's OK first. If a
  tool is missing and can't go through mise, stop and say what to install.

## 3. Create the app
- Use the stack's own generator (e.g. `flutter create .`, `npm create ...`)
  in the repo root, or in one folder per part for multi-part projects.
- Keep `AGENTS.md`, `README.md` and `docs/`. Merge the generator's
  `.gitignore` entries into the existing one instead of replacing it.
- Prefer the generator's defaults; change them only for a decision in the docs.

## 4. Checks
- Add one mise task per check, named `check:<name>` (e.g. `check:lint`,
  `check:test`). `mise run check` runs every `check:*` task, locally and in CI.
- Small projects: the stack's analyzer or linter and its tests are enough.
  Products: add formatting, type checks and a build where the stack has them.
- Maintainability: use the stack's recommended strict lint set rather than
  the minimum, and add checks for unused code and unused dependencies where
  the stack has tools for them. Products may add complexity limits.
- Run `mise run check` and make it pass before you finish.
- CI (`.github/workflows/check.yml`) runs `mise run check`. Tools pinned in
  `mise.toml` install there automatically; for anything else, add a setup
  step to the workflow.

## 5. AGENTS.md
- Fill in the placeholders in the project sections, above "Working
  agreements", following the guide. Run every command you write down.
- Write down how to run a single test, and how long the full run takes.
- Delete placeholder lines and sections that have nothing non-obvious to say.
- Never edit the "Working agreements" section: it is maintained in the blueprint.
- If `docs/architecture.md` exists, make it match the generated structure.

## 6. Finish
- Show the user the AGENTS.md project sections for review, and ask them to
  cut what they don't need: unedited generated files work worse.
- Commit according to the Git rules in AGENTS.md.
- If anything in this skill was wrong, missing or slowed you down, add a
  note to `docs/blueprint-feedback.md`.
