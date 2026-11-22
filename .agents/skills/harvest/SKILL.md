---
name: harvest
description: Collect blueprint feedback from projects created from this blueprint - read each project's docs/blueprint-feedback.md and new skills, decide what generalises, and propose the changes to the blueprint as one pull request. Blueprint only; init removes it from projects.
---

# Harvest

Goal: improvements found in projects reach the blueprint, and nothing a
project noted is lost. You propose; the user decides by reviewing the pull
request. Never write to the project repos.

## 1. Find the projects
- Search the user's GitHub repos for `docs/blueprint-feedback.md`, e.g.
  `gh api -X GET search/code -f q='filename:blueprint-feedback.md path:docs user:<owner>'`.
  Code search covers default branches only. If search is unavailable, ask
  the user for the list of project repos.
- Read [.blueprint/harvested.md](../../../.blueprint/harvested.md): the
  commit up to which each project was harvested, and the "Watching" list.

## 2. Read what is new
For each project:
- The entries in `docs/blueprint-feedback.md` added since the recorded
  commit (compare the file at that commit with the default branch).
- Skills in `.agents/skills/` that the blueprint doesn't have, or that
  changed from the blueprint's version.
- Use the harness's GitHub access or `gh`; in a cloud session, attach the
  repo read-only first.

## 3. Decide per finding
- **Adopt** when it would help most projects and either happened twice
  (here or on the Watching list) or is clearly a bug.
- **Watch** when it happened once: add it to the Watching list with the
  project and date. A second occurrence later makes it an adopt.
- **Reject** when it is project-specific, contradicts a decision in
  [.blueprint/LEARNINGS.md](../../../.blueprint/LEARNINGS.md) without new
  evidence, or only makes a file longer. Note the reason.
- Prefer deleting or sharpening a line over adding one.

## 4. Propose
- Make the adopted changes on a branch: working agreements in `AGENTS.md`,
  skills, guard, template or guide.
- Add a LEARNINGS entry per adopted decision, naming the projects it came from.
- Update `.blueprint/harvested.md`: the new commit per project and the
  Watching list.
- Run `mise run check`.
- Open one pull request. Its body lists every finding read, with project,
  decision (adopt / watch / reject) and reason. Don't merge it.
