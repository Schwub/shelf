---
id: TASK-34
title: Split shelf_data.dart
status: To Do
assignee: []
created_date: '2026-11-26T05:41:00Z'
labels: []
dependencies: []
ordinal: 35000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
app/lib/shelf/shelf_data.dart (827 lines) holds every model, the ShelfRepository interface for shelf, tags, filters and tracks, and SupabaseShelfRepository; every feature changes it and test/shelf/fake_shelf.dart grows with it (tech-debt review 2026-11-26). Split the models from the Supabase implementation; consider per-feature repositories. No behaviour change.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Models, the repository interface and the Supabase implementation live in separate files
- [ ] #2 mise run check and mise run test:integration pass unchanged
<!-- AC:END -->
