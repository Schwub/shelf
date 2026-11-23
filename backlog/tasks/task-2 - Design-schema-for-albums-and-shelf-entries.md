---
id: TASK-2
title: Design schema for albums and shelf entries
status: Done
assignee: []
created_date: '2026-11-22T22:05:00Z'
updated_date: '2026-11-23T07:48:00Z'
labels: []
dependencies: []
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Supabase migration for albums and shelf entries (status, rating, comment) with row-level security; see docs/architecture.md, Keep simple.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Migration in supabase/migrations
- [x] #2 RLS: users read and write only their own shelf entries
- [x] #3 Signed-in users read and add albums; nobody edits or deletes them from the client
- [x] #4 One entry per user and album; rating (optional, 1–10) and status reject invalid values
- [x] #5 pgTAP tests (mise run test:db) cover the rules
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Migration 20261123120000_albums_and_shelf_entries.sql; 23 pgTAP checks in supabase/tests, run by mise run test:db and the db workflow. Accepted debt in docs/tech-debt.md.
<!-- SECTION:NOTES:END -->
