---
id: TASK-15
title: Trial agent roles on the screen work
status: To Do
assignee: []
created_date: '2026-11-23T22:44:00Z'
labels: []
dependencies:
  - TASK-14
ordinal: 5900
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Define backend, frontend, design-reviewer and code-reviewer agents with short briefs pointing to docs/features/, docs/design/visual-system.md and AGENTS.md. After the theme exists, build independent screens (e.g. tag editor, album entry, filter menu) in parallel, each agent in its own worktree with the feature note as brief; an independent reviewer checks the combined result. Product and design decisions stay with the user.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Agent definitions exist and are documented in AGENTS.md
- [ ] #2 At least two screens built in parallel and merged, with an independent review
- [ ] #3 Short write-up: time saved, cost, problems, keep or drop
<!-- AC:END -->
