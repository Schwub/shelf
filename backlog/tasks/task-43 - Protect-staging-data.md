---
id: TASK-43
title: Protect staging data
status: To Do
assignee: []
created_date: '2026-11-26T14:34:00Z'
labels: []
dependencies: []
priority: high
ordinal: 44000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Testers use staging from now on, and the free plan keeps no backups we can download. Guard against losing their data: a backup before every migration push, a check that flags destructive migrations, and a written restore path.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The staging workflow dumps staging's data (supabase db dump --data-only) before db push and keeps it as a private artifact for a set time
- [ ] #2 The db workflow fails a pull request whose new migration drops a table or column, truncates or deletes rows, unless the migration says how the data is kept
- [ ] #3 docs/architecture.md describes how to restore a dump to staging
<!-- AC:END -->
