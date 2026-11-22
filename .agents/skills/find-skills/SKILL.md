---
name: find-skills
description: Find, vet and install third-party skills for the project's stack; proposes a few and installs only what the user approves. Use when setup or deliver calls it, or the user asks.
---

# Find skills

Goal: the few third-party skills that make agents better at this project's
actual stack, from sources worth trusting. More is not better: every skill
adds its description to every session, and overlapping skills give
conflicting advice.

## 1. Know the project
- Read `docs/project.md` (stack, interface, platforms) and, if present,
  `docs/architecture.md`.
- List what is installed: `.agents/skills/`, `skills-lock.json`.

## 2. Start from what worked before
- Read [candidates.md](candidates.md): the criteria, and skills already
  vetted for common stacks, with the date they were last checked.

## 3. Search
- One search per decision that matters: the framework and language, the
  platforms, testing, release and store submission, the interface:
  `DISABLE_TELEMETRY=1 npx skills@1.9.0 find "<query>"`. Always set
  `DISABLE_TELEMETRY=1`: the CLI reports usage otherwise.
- Look for skills published by the framework's own maintainers and by
  Anthropic (`DISABLE_TELEMETRY=1 npx skills@1.9.0 add anthropics/skills --list`).

## 4. Vet
Keep a candidate only if all of these hold:
- **Known source:** the framework's maintainers, the vendor of a tool the
  project uses, Anthropic, or an author with a visible track record.
- **Licence** that allows use and copying.
- **Maintained:** changes within the last six months, or clearly stable.
- **Read it:** read `SKILL.md` and every bundled script. No hidden network
  calls, no instructions to fetch and run remote code, nothing that
  contradicts AGENTS.md or the working agreements.
- **Earns its place:** not covered by an installed skill, by AGENTS.md, or
  by what agents already do well without it.

## 5. Propose and install
- Propose two to four skills in a table: name, source, licence, what it
  does, which project decision it serves. Recommend; the user decides.
- Install each approved skill:
  `DISABLE_TELEMETRY=1 npx skills@1.9.0 add <owner/repo> --skill <name> --agent claude-code pi -y`.
- Read the installed `SKILL.md` once more, then commit the folder in
  `.agents/skills/`, its link in `.claude/skills/` and `skills-lock.json`.

## 6. Finish
- A skill that proved useful, or a candidate that disappointed, goes to
  `docs/blueprint-feedback.md`, so [candidates.md](candidates.md) improves.
