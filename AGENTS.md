# AGENTS.md

## Commands
Run Flutter commands in `app/` through mise (`mise exec -- flutter ...`):
mise isn't activated in the shell, and `flutter`/`dart` there may be
aliased to fvm with a different version.
- Run one test: `cd app && mise exec -- flutter test test/widget_test.dart`
- Full check before finishing: `mise run check` (format, analyze, tests,
  web build; ~30 s warm, a few minutes cold)
- Database tests (Docker; run after changing `supabase/`): `mise run test:db`
- Edge function tests (run after changing `supabase/functions/`; not part of
  `mise run check`): `mise run test:functions`
- Integration tests (Docker; run after changing `app/lib/shelf/shelf.dart`,
  a `supabase_*_repository.dart` or migrations): `mise run test:integration`
  (the Supabase repositories against a local Supabase, `app/test_integration/`)
- Cloud sessions: use the "shelf" environment (its setup script installs the
  tools). Docker isn't started for you: if `docker info` fails, run
  `dockerd >/tmp/dockerd.log 2>&1 &` and wait a few seconds.
- Web deploys run in CI (`web` workflow, Cloudflare Pages): `main` goes to
  production, each PR gets a preview URL posted on the PR. No local deploy
  command; setup in `docs/architecture.md`, "Web deploys".
- Native builds (iOS not in CI; Android also built by the `android` workflow
  on pull requests that change `app/android`, pubspec or `mise.toml`;
  run after changing `app/ios` or `app/android`):
  `mise exec -- flutter build ios --debug --no-codesign` and
  `mise exec -- flutter build apk --debug` (~2.5 min), both in `app/`.
  iOS builds take 3–18 min here, mostly idle in Xcode's package resolution;
  run them in the background.
- Tasks live in `backlog/` (Backlog.md): `mise exec -- backlog task list --plain`,
  `backlog task view <id> --plain`, `backlog task edit <id> -s "In Progress"`,
  `backlog task edit <id> --check-ac <n> -s Done`,
  `backlog task create "<title>" --ac "<criterion>"`. Edit task files with
  the CLI, not by hand (they contain marker comments).

## Done means
- `mise run check` passes and new behaviour has a test.
- Changes to `app/ios` or `app/android` also pass the native build for that
  platform.

## Conventions
- New skills go in `.agents/skills/<name>/SKILL.md` (Agent Skills standard), linked into Claude Code with `ln -s ../../.agents/skills/<name> .claude/skills/<name>`; no Claude-only frontmatter.

## Boundaries
- Ask first: changing the app ID `de.schwubware.shelf`; running
  `supabase link`, `db push` or `functions deploy` (they touch the hosted
  project).
- Staging holds testers' real data (from 2026-11-26): migrations keep
  existing rows (move data before dropping a column or table, never
  truncate or delete user data), and nothing may reset or wipe the staging
  database (`supabase db reset --linked` or similar).

## Where to look
- Goal, scope, milestones and risks: `docs/project.md`.
- Intended architecture and key decisions: `docs/architecture.md`.
- Flutter 3.50 and Supabase CLI 3.x may be newer than your training: check
  `--help` or the official docs before relying on remembered flags or APIs.

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
- In a project, files listed in `.agents/managed.txt` and this section come
  from the blueprint and `mise run agentic:update` overwrites them: don't
  edit them; note what's wrong in `docs/blueprint-feedback.md`.
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
