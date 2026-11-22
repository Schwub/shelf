---
name: project-management
description: Decide how a project tracks its tasks and set it up - from no tracker (a list in docs/project.md) to a task tool - using fixed criteria and a maintained candidate list. Use during project setup, or when a project outgrows how it tracks work.
---

# Project management

Goal: the lightest way of tracking work that fits this project, chosen
against fixed criteria, set up so any agent can use it, and recorded.

## 1. Understand the need
- Read `docs/project.md` (size, lifetime, who works on it, first steps)
  and the current setup, if the project already tracks tasks somehow.
- Ask only what the docs leave open: will others work on it? Is a board
  wanted? How many steps does the first version have?

## 2. Check the candidates
- Read [candidates.md](candidates.md): the criteria, the candidates and
  when the list was last checked.
- If the list is older than three months, or the project needs something
  the list doesn't cover, look up the current state of the candidates and
  any new, well-established option. Judge every option against the criteria.
- Small projects usually need no tool: the "First steps" list in
  `docs/project.md` is enough until it isn't.

## 3. Decide with the user
- Propose one or two options with trade-offs and recommend one.
- Any option that fails a criterion is out, however popular.

## 4. Set it up
- Pin the tool's version in `mise.toml` `[tools]`, preferring a release
  that has been out for a few weeks over one from the last days.
- Before relying on it, test in a scratch folder what it does to git: does
  it commit, which files does it write or change (AGENTS.md, `.claude/`,
  git hooks)? Turn off whatever breaks the criteria, or drop the tool.
- Configure it, and move the "First steps" from `docs/project.md` into it.
- Add one line under Commands in `AGENTS.md`: where tasks live and the
  commands to find, update and close one.
- Run `mise run check`.

## 5. Record and finish
- Record the decision with its reason: in the decisions of
  `docs/architecture.md` if it exists, otherwise under Stack in `docs/project.md`.
- If a candidate behaved differently than [candidates.md](candidates.md)
  says, or you found a better one, add a note to `docs/blueprint-feedback.md`.
