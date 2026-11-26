---
id: TASK-47
title: Back up staging data outside GitHub
status: To Do
assignee: []
created_date: '2026-11-26T21:29:00Z'
labels: []
dependencies: []
ordinal: 48000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Before each migration push, dump staging's data (supabase db dump --data-only, auth included) and upload it to a private Cloudflare R2 bucket from the staging workflow, with an API token secret only the owner can read; old backups expire. Not GitHub artifacts: collaborators can download those (decided 2026-11-26, TASK-43).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The staging workflow uploads a dump to R2 before db push and stops if that fails
- [ ] #2 Backups older than 30 days are deleted by the bucket's lifecycle rule
- [ ] #3 docs/architecture.md describes how to restore a dump, tried once on a local Supabase
<!-- AC:END -->
