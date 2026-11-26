---
id: TASK-34
title: Split shelf_data.dart
status: Done
assignee: []
created_date: '2026-11-26T05:41:00Z'
updated_date: '2026-11-26T07:46:00Z'
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
- [x] #1 Models, the repository interface and the Supabase implementation live in separate files
- [x] #2 mise run check and mise run test:integration pass unchanged
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Split into shelf.dart (models), shelf_repository.dart (interface, DuplicateName, SeveralTags) and supabase_shelf_repository.dart. mise run check (208) and test:integration (5) pass; only imports changed in tests. Per-feature repositories left for later.
<!-- SECTION:NOTES:END -->
