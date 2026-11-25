---
id: TASK-9
title: Show and edit my shelf
status: Done
assignee: []
created_date: '2026-11-23T17:42:00Z'
updated_date: '2026-11-25T00:18:00Z'
labels: []
dependencies:
  - TASK-5
  - TASK-6
ordinal: 9000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
List the signed-in user's shelf entries and edit an entry's rating and comment. Tags on the entry are TASK-16; design in docs/design/visual/screens/ and docs/features/tags.md.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Widget tests cover the list, the empty state and editing
- [x] #2 The shelf lists entries with cover, title, artist and rating (no tags on the tiles), with an empty state
- [x] #3 Rating and comment can be changed and are saved
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
My shelf (lib/shelf): covers on boards and spines (pull up, then open), filter bar with counts from shelf_filters (hidden groups left out), loading, empty, error and no-match states, sign-out menu; development builds keep the component page under ⋮. Album entry in edit mode: rating keys, comment, save errors, Discard changes?, remove with Undo (the delete runs when the snackbar closes). Not yet: covers/spines choice kept on the device (needs shared_preferences, a new dependency), spine colours from the covers (fixed palette for now), Add album key (TASK-8), tags on the entry (TASK-16). Test albums: supabase/dev/test_albums.sql, mise run dev:albums, staging-test-albums workflow.
<!-- SECTION:NOTES:END -->
