---
id: TASK-43
title: Protect staging data
status: Done
assignee: []
created_date: '2026-11-26T14:34:00Z'
updated_date: '2026-11-26T21:29:00Z'
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
- [x] #1 The db workflow fails a pull request whose new migration drops a table or column, truncates or deletes rows, unless the migration says how the data is kept
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-11-26: supabase/check-migrations.sh (+ .test.sh) in the db workflow on pull requests; also fails edits to merged migrations; ignores function bodies. Backups moved to TASK-47 (R2, not GitHub artifacts: collaborators can download those).
<!-- SECTION:NOTES:END -->
