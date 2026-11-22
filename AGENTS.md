# AGENTS.md

## Commands
- Install: `<command>`
- Run one test: `<command>`
- Run all tests: `<command>` (<takes ~N min; use the single-test form while iterating>)
- Lint / typecheck: `<command>`
- Full check before finishing: `<command>`

## Done means
- `<full check command>` passes and new behaviour has a test.

## Conventions
- <Where this repo differs from common defaults> (<short reason>).
- New <kind of code> follows `<path/to/exemplar>`.
- New skills go in `.agents/skills/<name>/SKILL.md` (Agent Skills standard), linked into Claude Code with `ln -s ../../.agents/skills/<name> .claude/skills/<name>`; no Claude-only frontmatter.

## Gotchas
- <Misleading code, e.g. a live legacy folder that shouldn't be copied>
- <Environment, e.g. required env vars, services, generated files and how to regenerate them>

## Boundaries
- Ask first: <only what the working agreements don't cover, e.g. migrations, changing CI>
- Never: <e.g. edit vendor/, commit secrets> (enforced by <pre-commit / CI>)

## Git and PRs
- <Branch naming, commit and PR format, attribution policy>

## Where to look
- Intended architecture and key decisions: `docs/architecture.md`.
- Working on <area>: read `<docs/area.md>` first.
- <Library or API newer than the model's training>: read `<docs/lib/INDEX.md>` before using it.

# Working agreements

My defaults, the same in every project; change them only in the blueprint.
The project sections above override them, except the "always ask" list and
the Git rules. If my request conflicts with a project rule, point out the
conflict and ask.

## Communication
- If I ask a question (why, how, what), investigate read-only and answer;
  edit only when I ask for a change.
- Be concise: conclusion first, then reasoning; more detail only if I ask.
- No canned enthusiasm or praise.
- If you disagree with my feedback, say why before changing anything.

## When to ask
- For open-ended or larger work (a new module, a multi-file design), propose
  the approach and wait for my OK. If a plan looks over- or
  under-engineered, say so.
- If the request can reasonably be read in ways that lead to different
  results, ask first. Don't ask about things you can find out yourself.
- When no one can answer (you're a subagent, or the brief says to work
  unattended), state your assumptions and proceed within the brief. For
  anything on the "always ask" list or a rule conflict, stop and report instead.
- Always ask before:
  - adding a production dependency
  - changing a public API or schema
  - removing intentional-looking code that the request doesn't replace
  - anything that installs or changes things outside the repo (brew, npm -g,
    pip outside a venv, shell config), including via project scripts you
    haven't read
  - touching production systems, real credentials or secrets, or data that
    isn't disposable

## Changes
- Follow how this codebase already solves similar problems and reuse its
  helpers. If you think it should deviate, say so.
- Make the smallest change that solves the request; every changed line,
  tests included, should trace to it. No speculative abstractions, options,
  or error handling for cases that can't happen.
- Outside the task, point out bugs, risks, duplication or dead code you
  notice. Don't fix them unless I ask.
- When you replace or refactor something, delete the old code path: no
  compatibility wrappers, fallbacks or unused parameters unless I ask.
- Remove what your change made unused; leave pre-existing dead code alone.
- Comment only the why that the code can't show; don't narrate the change.

## Verification
- Where practical, reproduce a bug with a failing test before fixing it.
- Before finishing, review your own diff once: if it can be simpler or
  clearer, simplify it within the task.
- Before saying done, run the checks the project defines for done. If you
  couldn't verify something, say so.
- Tests of code the task removes go with it; otherwise never weaken, skip or
  delete tests, or add ignores, to make checks pass.
- If the same approach fails twice, stop and report instead of piling on
  workarounds.
- Before finishing: if a working agreement or skill misled you or was
  missing, or a skill you built would help other projects, add a short note
  to `docs/blueprint-feedback.md`.

## Engineering excellence
- Less code is better: prefer the simplest solution that stays maintainable.
- For new designs or unfamiliar problems, look for established solutions
  (standard library, well-known packages, documented patterns) before
  inventing your own. Inside an existing codebase, its patterns come first.
- Suggest improvements beyond the code (tests, infrastructure, linting) when
  they'd make the project more maintainable.

## Git
- Never commit, push, force-push or rewrite history (incl. --amend) unless
  I ask. Never bypass hooks with --no-verify.
- Never discard or overwrite uncommitted changes you didn't make (reset
  --hard, checkout/restore, clean, stash, repo-wide formatters or --fix runs)
  or delete files outside the task without asking.
- Commit only files you changed for this task, staged by explicit path
  (never `git add -A` or `git add .`); unknown changes belong to someone else.
- Exception: in a clone-mode sandbox (`sbx run --clone`), commit finished
  work to a task branch without asking; never push.
- Exception: in a cloud session (e.g. Claude Code on the web), commit finished
  work to the session's branch and push it without asking; never push to
  another branch.
