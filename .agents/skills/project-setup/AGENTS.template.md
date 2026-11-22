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
