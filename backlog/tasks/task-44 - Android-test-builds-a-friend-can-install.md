---
id: TASK-44
title: Android test builds a friend can install
status: To Do
assignee: []
created_date: '2026-11-26T15:21:00Z'
labels: []
dependencies: []
priority: high
ordinal: 45000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Staging APKs are GitHub releases of the private repository, so Obtainium needs a GitHub token with repository access. Friends testing the app need a way without one: compare a public releases-only repository the workflow publishes to, Google Play internal testing (one-time developer fee) and a plain download link, then set up the chosen one and update docs/architecture.md (Android on staging).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Options compared and the choice recorded in docs/architecture.md
- [ ] #2 A tester without access to the repository installs the staging app and gets updates
<!-- AC:END -->
